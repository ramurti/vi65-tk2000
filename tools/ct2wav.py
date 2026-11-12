#!/usr/bin/env python3
"""Converte um arquivo .ct2 (fita do TK2000) em WAV para carregar com LOADT.

Reaproveita os tempos medidos numa gravação real do TK2000 (os mesmos do bas2wav.py):
  piloto : 9468 meios-ciclos de ~493 us            (um por arquivo gravado, marcador CA)
  bloco  : 63 meios-ciclos de ~666 us + sync (204 us + 238 us) + bytes   (marcador CB + DA)
  bit 0  : 2 meios-ciclos de ~246 us
  bit 1  : 2 meios-ciclos de ~493 us
  bytes  : MSB primeiro; os bytes do bloco DA já trazem o checksum

Uso: python3 ct2wav.py jogo.ct2 [jogo.wav] [pausa_entre_arquivos_em_segundos]
"""
import sys
import wave

SAMPLE_RATE = 44100
AMPLITUDE = 110            # 128 +/- 110 (8 bits sem sinal)
PILOT_US, PILOT_N = 493, 9468
LEAD_US, LEAD_N = 666, 63
SYNC_US = (204, 238)
BIT0_US, BIT1_US = 246, 493


class Wave:
    def __init__(self):
        self.samples = bytearray()
        self.t = 0.0          # tempo acumulado em amostras (evita erro de arredondamento)
        self.n = 0
        self.level = 0

    def half(self, us):
        self.t += us * SAMPLE_RATE / 1e6
        end = round(self.t)
        v = 128 + AMPLITUDE if self.level else 128 - AMPLITUDE
        self.samples.extend(bytes([v]) * (end - self.n))
        self.n = end
        self.level ^= 1

    def silence(self, sec):
        self.samples.extend(bytes([128]) * int(sec * SAMPLE_RATE))
        self.n = len(self.samples); self.t = float(self.n)

    def byte(self, b):
        for k in range(7, -1, -1):
            us = BIT1_US if (b >> k) & 1 else BIT0_US
            self.half(us); self.half(us)

    def block(self, data):
        for _ in range(LEAD_N):
            self.half(LEAD_US)
        self.half(SYNC_US[0]); self.half(SYNC_US[1])
        for b in data:
            self.byte(b)


def ler_ct2(dados):
    """Devolve uma lista de arquivos; cada arquivo é uma lista de blocos (bytes com checksum)."""
    if dados[:4] != b"CTK2":
        raise ValueError("não é um arquivo .ct2 (faltou o cabeçalho 'CTK2')")
    arquivos, pos = [], 4
    while pos < len(dados):
        tag = dados[pos:pos + 2]
        if tag == b"CA":
            arquivos.append([])
            pos += 4
        elif tag == b"CB":
            pos += 4
        elif tag == b"DA":
            if pos + 4 > len(dados):
                raise ValueError(f"arquivo cortado no byte {pos}")
            n = dados[pos + 2] | (dados[pos + 3] << 8)
            bloco = dados[pos + 4:pos + 4 + n]
            if len(bloco) != n:
                raise ValueError(f"bloco DA cortado no byte {pos}")
            if not arquivos:
                arquivos.append([])
            arquivos[-1].append(bloco)
            pos += 4 + n
        else:
            raise ValueError(f"marcador desconhecido {tag!r} no byte {pos}")
    return arquivos


def gerar_wav(ct2_filename, wav_filename, pausa=2.0):
    with open(ct2_filename, "rb") as f:
        arquivos = ler_ct2(f.read())

    w = Wave()
    w.silence(1.0)
    for i, blocos in enumerate(arquivos):
        if i:
            w.silence(pausa)
        for _ in range(PILOT_N):
            w.half(PILOT_US)
        for b in blocos:
            w.block(b)
        w.half(LEAD_US)        # borda final que fecha o último bit do checksum
    w.silence(1.0)

    with wave.open(wav_filename, "w") as wf:
        wf.setnchannels(1); wf.setsampwidth(1); wf.setframerate(SAMPLE_RATE)
        wf.writeframes(bytes(w.samples))
    total = sum(len(b) for bl in arquivos for b in bl)
    print(f"{wav_filename}: {len(arquivos)} arquivo(s), {sum(len(a) for a in arquivos)} bloco(s), "
          f"{total} bytes, {len(w.samples)/SAMPLE_RATE:.2f} s")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python3 ct2wav.py arquivo.ct2 [saida.wav] [pausa_entre_arquivos_em_segundos]")
        sys.exit(1)
    src = sys.argv[1]
    dst = sys.argv[2] if len(sys.argv) > 2 else src.rsplit(".", 1)[0] + ".wav"
    try:
        gerar_wav(src, dst, float(sys.argv[3]) if len(sys.argv) > 3 else 2.0)
    except (OSError, ValueError) as e:
        print(f"[Erro] {e}")
        sys.exit(1)

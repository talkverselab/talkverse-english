#!/usr/bin/python3
"""감정 계획 → PC 작업 파일(D:\\tts_test\\job 에 넣는다). 영어.
PC 출력은 out/en/<편>/, 참고 음성은 out/ref_en/ 에 둔다(편 id·목소리 이름이 언어마다 겹쳐 다른 언어 결과를 건너뛰어 버림).
  python3 tools/tts/make_jobs.py <출력폴더> --refs [편id...]   쓰이는 (목소리, 감정) 참고 음성 → vox_jobs.json (편을 주면 그 편들만)
  python3 tools/tts/make_jobs.py <출력폴더> <편id>...          문장 조각 → moss_jobs.json(MOSS, language English) — `<편>_vox` 는 vox_jobs.json 뒤에 덧붙인다(VoxCPM2)
같은 작업에서 vox_jobs(2060)가 먼저, moss_jobs(3090)가 뒤에 돈다. 참고 음성 → 문장 순서가 지켜진다."""
import json, os, sys
import ttslib as L


def main():
    out, eps = sys.argv[1], sys.argv[2:]
    vf = f'{out}/vox_jobs.json'
    if eps and eps[0] == '--refs':
        ids = [L.base(e) for e in eps[1:]] or L.planned()
        need = sorted({(v, e) for ep in ids for _, v, e, _ in L.seg_files(ep)})
        vox = [{'out': f'{L.REF}/{v}_base.wav', 'text': L.V['base_text'], 'instruct': L.V['voices'][v]['desc']} for v in sorted({v for v, _ in need})]
        for v, e in need:
            x, E = L.V['voices'][v], L.V['emotions'][e]
            vox.append({'out': f'{L.REF}/{v}_{e}.wav', 'text': E['ref'], 'instruct': f"{x['desc']}, {E['instruct']}", 'reference': f'out/{L.REF}/{v}_base.wav'})
        json.dump(vox, open(vf, 'w', encoding='utf-8'), ensure_ascii=False, indent=0); print(len(vox), 'vox 참고 음성'); return
    moss = [L.job(ep, f, v, e, text) for ep in eps if not ep.endswith(L.VOX) for f, v, e, text in L.seg_files(ep)]
    vox = [L.job(ep, f, v, e, text) for ep in eps if ep.endswith(L.VOX) for f, v, e, text in L.seg_files(ep)]
    if moss:
        json.dump(moss, open(f'{out}/moss_jobs.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    if vox:
        old = json.load(open(vf, encoding='utf-8')) if os.path.exists(vf) else []
        json.dump(old + vox, open(vf, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    print(len(moss), 'moss', len(vox), 'vox 문장')


if __name__ == '__main__':
    main()

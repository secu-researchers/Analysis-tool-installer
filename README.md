# 분석 VM 도구 설치 목록 (Windows 11)
 
`install_analysis_tools.bat` 기준 최신 목록입니다. 관리자 권한으로 실행하며, 로그는 `C:\Tools\install_log.txt`에 남습니다.
 
**설치 방식 범례**
 
- **winget**: Windows 패키지 관리자로 설치
- **GitHub 릴리스**: 최신 릴리스 zip을 받아 `C:\Tools\<폴더>`에 압축 해제
- **pip**: Python 3.13의 pip로 설치
- **go install**: Go로 빌드하여 `C:\Tools\go-bin`에 설치 (PATH 자동 등록)
---
 
## 1. 기본 개발 환경
 
| 프로그램명 | 사용 목적 | 설치 방식 |
|---|---|---|
| Bandizip | 압축·해제 (악성 샘플 zip 처리 포함) | winget |
| Python 3.13.14 | 분석 스크립트 실행, pip 도구 구동 | winget |
| Visual Studio Code | 코드 편집기 | winget |
| Git | 소스 다운로드·버전 관리 | winget |
| Temurin JDK 21 | Ghidra 실행용 Java | winget |
| Go | ProjectDiscovery 등 Go 도구 빌드·설치 | winget |
 
## 2. 리버스 엔지니어링
 
| 프로그램명 | 사용 목적 | 설치 방식 |
|---|---|---|
| Ghidra | 정적 분석·디컴파일 | winget |
| x64dbg | Windows 동적 분석·디버깅 | winget |
| Cutter | radare2 기반 GUI 리버싱 | winget |
| PE-bear | PE 헤더·섹션·임포트 분석 | winget |
| PeStudio | PE 정적 분석 (임포트, 문자열, 의심 지표, VirusTotal 조회) | winitor.com zip → `C:\Tools\pestudio` |
| ILSpy | .NET 디컴파일러 | winget |
| dnSpyEx | .NET 디컴파일·디버깅 | GitHub 릴리스 → `C:\Tools\dnSpyEx` |
| Detect It Easy | 패커·컴파일러·파일 형식 식별 | GitHub 릴리스 → `C:\Tools\DIE` |
| capa | 실행 파일 기능(Capability) 자동 식별 | GitHub 릴리스 → `C:\Tools\capa` |
| FLOSS | 난독화된 문자열 추출 | GitHub 릴리스 → `C:\Tools\floss` |
| jadx | Android APK 디컴파일 | GitHub 릴리스 → `C:\Tools\jadx` |
| YARA | 악성코드 탐지 룰 작성·매칭 | GitHub 릴리스 → `C:\Tools\yara` |
| HxD | 헥스 에디터 | winget |
| System Informer | 프로세스·메모리·핸들 분석 | winget |
| Sysinternals Suite | Process Monitor, Autoruns, TCPView 등 행위 분석 | winget |
| Wireshark | 네트워크 패킷 분석 (Npcap 포함) | winget |
| Frida (frida-tools) | 동적 계측·후킹 | pip |
| pefile | PE 파일 파싱 라이브러리 | pip |
| yara-python | YARA 파이썬 바인딩 | pip |
 
## 3. 해킹메일 분석
 
| 프로그램명 | 사용 목적 | 설치 방식 |
|---|---|---|
| Thunderbird | EML 원본·헤더 확인 (격리 VM에서 사용) | winget |
| CyberChef | Base64·URL 디코딩, 난독화 해제 | GitHub 릴리스 → `C:\Tools\CyberChef` |
| oletools | Office 매크로(VBA)·OLE 분석 | pip |
| Didier Stevens Suite | PDF·악성 문서 분석 (pdfid, pdf-parser 등) | didierstevens.com zip → `C:\Tools\DidierStevensSuite` |
| ExifTool | 첨부파일 메타데이터 추출 | winget |
 
## 4. 취약점 진단
 
| 프로그램명 | 사용 목적 | 설치 방식 |
|---|---|---|
| Nmap | 포트·서비스 스캔 | winget |
| Burp Suite Community | 웹 프록시·웹 취약점 진단 | winget |
| Trivy | 컨테이너·IaC·패키지 취약점 스캔 | GitHub 릴리스 → `C:\Tools\trivy` |
 
## 5. 버그바운티 (정찰·자산 탐색)
 
| 프로그램명 | 사용 목적 | 설치 방식 |
|---|---|---|
| Subfinder | 서브도메인 수집 | go install |
| httpx | 살아있는 호스트·기술 스택 확인 | go install |
| Katana | 웹 크롤링·엔드포인트 수집 | go install |
| Nuclei | 템플릿 기반 취약점 스캔 | go install |
| ffuf | 디렉터리·파라미터 퍼징 | go install |
| Amass | 공격 표면·자산 매핑 | go install |
| requests | HTTP 스크립트 작성용 라이브러리 | pip |
 
---
 
## 유의사항
 
- **스냅샷**: 설치 전후로 VM 스냅샷을 만들어 두세요.
- **패키지 ID**: winget 패키지 ID가 맞지 않으면 해당 항목만 실패하고 건너뜁니다. 실패 시 `winget search 이름`으로 정확한 ID를 확인하세요.
- **다운로드 주소**: PeStudio, Didier Stevens Suite의 직접 다운로드 주소는 변경될 수 있습니다. 실패하면 공식 사이트에서 직접 받으세요.
- **PATH**: 설치 후 재부팅 또는 재로그인하여 Python, Go, Git의 PATH를 적용하세요. GitHub 릴리스 도구는 압축 해제만 하므로 필요한 폴더를 PATH에 추가하세요.
- **Defender**: 분석 도구가 악성으로 탐지될 수 있습니다. 분석 전용 VM에서만 사용하고, 예외 처리는 `C:\Tools`에만 적용하세요.
- **네트워크 격리**: 악성코드 분석 시에는 Host-only 또는 격리망을 사용하고, 공유 폴더·클립보드는 끄세요.
- **버그바운티**: 반드시 프로그램의 Scope와 규정 안에서만 스캔하세요.

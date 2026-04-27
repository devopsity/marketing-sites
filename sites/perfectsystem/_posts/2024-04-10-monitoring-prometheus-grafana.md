---
layout: post
title: "Monitoring z Prometheus i Grafana — przewodnik dla startupów"
description: "Jak wdrożyć monitoring z Prometheus i Grafana w startupie. Metryki, alerty, dashboardy i observability — praktyczny przewodnik od zera do produkcji."
author: george
date: 2024-04-10
last_modified: 2024-05-01
lang: pl
content_type: post
cluster: devops-automation
keywords:
  - "Prometheus"
  - "Grafana"
  - "monitoring startup"
  - "observability"
image: /assets/images/4.jpg
categories:
  - devops
tags:
  - monitoring
  - prometheus
  - grafana
  - observability
summary: "Prometheus to open-source'owy system zbierania i przechowywania metryk, a Grafana to platforma wizualizacji danych. Razem tworzą standard branżowy monitoringu infrastruktury i aplikacji. Dla startupów ten stos oferuje pełną observability bez kosztów licencyjnych — od metryk systemowych po alerty na Slacku."
faq:
  - q: "Czy Prometheus i Grafana są darmowe?"
    a: "Tak, oba narzędzia są open-source i darmowe do użytku komercyjnego. Grafana Cloud oferuje darmowy tier z 10 000 serii metryk, 50 GB logów i 50 GB traces miesięcznie — wystarczająco dla startupu na wczesnym etapie. Płatne plany zaczynają się od 29 USD/miesiąc."
  - q: "Ile zasobów potrzebuje Prometheus?"
    a: "Prometheus jest zaskakująco lekki. Dla startupu monitorującego 10-20 serwisów z retencją 15 dni wystarczy 2 GB RAM i 20 GB dysku SSD. Zużycie rośnie liniowo z liczbą monitorowanych serii czasowych — planuj około 1-2 KB RAM na serię."
definitions:
  - term: "Metryka"
    definition: "Numeryczna wartość mierzona w czasie, opisująca stan systemu — na przykład zużycie CPU, czas odpowiedzi HTTP, liczba aktywnych połączeń do bazy danych. Metryki są podstawą monitoringu i alertingu."
  - term: "PromQL"
    definition: "Prometheus Query Language — język zapytań do przeszukiwania i agregowania metryk w Prometheus. PromQL pozwala obliczać średnie, percentyle, rate i inne statystyki na danych czasowych."
backlink_target: "https://devopsity.com/pl/uslugi/observability/"
backlink_anchor: "usługi observability od Devopsity"
sources:
  - url: "https://prometheus.io/docs/"
    title: "Prometheus Documentation"
  - url: "https://grafana.com/docs/"
    title: "Grafana Documentation"
---

## Dlaczego monitoring jest krytyczny dla startupów

Wdrażanie bez monitoringu to jazda z zamkniętymi oczami. Możesz jechać szybko, ale nie wiesz, czy droga jest prosta, czy zaraz skręca w przepaść. Dla startupów, które wdrażają zmiany kilka razy dziennie, brak monitoringu oznacza, że problemy odkrywają użytkownicy — a to najgorszy możliwy sposób na dowiedzenie się o awarii.

Monitoring odpowiada na trzy fundamentalne pytania: czy system działa (dostępność), jak szybko działa (wydajność) i co się zmieniło (diagnostyka). Bez odpowiedzi na te pytania każde wdrożenie to loteria — może zadziała, może nie, a jeśli nie, to nie wiadomo dlaczego.

Prometheus i Grafana to standard branżowy monitoringu open-source. Prometheus zbiera i przechowuje metryki, Grafana je wizualizuje, a Alertmanager powiadamia zespół o problemach. Ten stos jest używany przez firmy od startupów po korporacje — SoundCloud (twórca Prometheus), GitLab, DigitalOcean i tysiące innych.

Ten artykuł jest częścią naszego [kompletnego przewodnika po automatyzacji DevOps dla startupów](/pillars/automatyzacja-devops-startupy/), który omawia wszystkie filary automatyzacji — od CI/CD po bezpieczeństwo pipeline.

## Architektura Prometheus i Grafana

Zrozumienie architektury pomaga w prawidłowym wdrożeniu i rozwiązywaniu problemów. Stos Prometheus-Grafana składa się z kilku komponentów, z których każdy pełni określoną rolę.

### Prometheus — serce monitoringu

Prometheus działa w modelu pull — aktywnie odpytuje (scrape) endpointy metryk w zdefiniowanych interwałach (domyślnie co 15 sekund). Każda aplikacja i komponent infrastruktury eksponuje endpoint `/metrics` w formacie tekstowym, a Prometheus zbiera te dane i przechowuje je w lokalnej bazie danych szeregów czasowych (TSDB).

Ten model ma kluczową zaletę — Prometheus wie, które targety są dostępne, a które nie. Jeśli target nie odpowiada, Prometheus rejestruje to jako problem. W modelu push (gdzie aplikacja wysyła metryki) brak danych może oznaczać zarówno problem, jak i po prostu brak aktywności.

### Grafana — wizualizacja i dashboardy

Grafana łączy się z Prometheus jako źródłem danych i pozwala tworzyć dashboardy z wykresami, tabelami i wskaźnikami. Dashboardy są konfigurowalne — możesz tworzyć widoki dla różnych odbiorców: przegląd systemu dla managementu, szczegółowe metryki dla developerów, alerty dla on-call.

Grafana wspiera wiele źródeł danych jednocześnie — Prometheus dla metryk, Loki dla logów, Tempo dla traces. To pozwala korelować dane z różnych źródeł na jednym dashboardzie — na przykład nałożyć wykres error rate na timeline deploymentów.

### Alertmanager — powiadomienia

Alertmanager to komponent Prometheus odpowiedzialny za routing i wysyłanie alertów. Prometheus definiuje reguły alertów (np. „error rate > 5% przez 5 minut"), a Alertmanager decyduje, kto i jak zostanie powiadomiony — Slack, PagerDuty, email, webhook.

Alertmanager obsługuje grupowanie (wiele powiązanych alertów w jednym powiadomieniu), wyciszanie (silence — tymczasowe wyłączenie alertu podczas planowanych prac) i eskalację (jeśli nikt nie zareaguje w ciągu 15 minut, alert trafia do kolejnej osoby).

## Wdrożenie Prometheus krok po kroku

Przejdźmy do praktyki. Wdrożymy Prometheus dla typowej aplikacji webowej startupu uruchomionej na kontenerach.

### Instalacja i konfiguracja

Najprostszy sposób uruchomienia Prometheus to kontener Docker. Plik konfiguracyjny `prometheus.yml` definiuje globalne ustawienia (interwał scrapowania, reguły alertów) i listę targetów do monitorowania.

Dla środowiska produkcyjnego na Kubernetes, kube-prometheus-stack (Helm chart) instaluje Prometheus, Grafanę, Alertmanager i zestaw gotowych dashboardów i reguł alertów w kilka minut. To rekomendowany sposób wdrożenia dla startupów korzystających z Kubernetes.

### Instrumentacja aplikacji

Aby Prometheus mógł zbierać metryki z Twojej aplikacji, musisz ją zinstrumentować — dodać endpoint `/metrics` eksponujący metryki w formacie Prometheus. Biblioteki klienckie są dostępne dla wszystkich popularnych języków: Go, Java, Python, Node.js, Ruby, .NET.

Cztery podstawowe typy metryk to Counter (wartość rosnąca — liczba żądań, błędów), Gauge (wartość zmienna — zużycie pamięci, aktywne połączenia), Histogram (rozkład wartości — czas odpowiedzi z percentylami) i Summary (podobny do histogramu, ale obliczany po stronie klienta).

### Metryki infrastruktury

Node Exporter zbiera metryki systemowe z serwerów Linux — CPU, pamięć, dysk, sieć. cAdvisor zbiera metryki kontenerów Docker — zużycie zasobów per kontener. Blackbox Exporter monitoruje dostępność endpointów HTTP, TCP i ICMP z zewnątrz. Te exportery pokrywają podstawowe potrzeby monitoringu infrastruktury bez zmian w kodzie aplikacji.

## Konfiguracja Grafana — dashboardy i wizualizacja

Grafana zamienia surowe metryki w czytelne dashboardy. Dobrze zaprojektowany dashboard daje natychmiastowy wgląd w stan systemu — bez konieczności pisania zapytań PromQL.

### Gotowe dashboardy

Grafana.com oferuje tysiące gotowych dashboardów do importu. Dla startupu na start rekomendujemy: Node Exporter Full (metryki systemowe), Docker Container Monitoring (metryki kontenerów) i dedykowany dashboard dla Twojej aplikacji. Import gotowego dashboardu to kwestia wklejenia ID — Grafana pobiera konfigurację automatycznie.

### Projektowanie własnych dashboardów

Własne dashboardy powinny odpowiadać na konkretne pytania biznesowe i techniczne. Dashboard „Overview" pokazuje kluczowe wskaźniki: dostępność serwisów, czas odpowiedzi (p50, p95, p99), error rate, liczbę aktywnych użytkowników. Dashboard „Infrastructure" pokazuje zużycie zasobów: CPU, pamięć, dysk, sieć per serwis. Dashboard „Business" pokazuje metryki biznesowe: rejestracje, transakcje, konwersje.

Kluczowa zasada — dashboard powinien być czytelny na pierwszy rzut oka. Używaj kolorów konsekwentnie (zielony = OK, żółty = ostrzeżenie, czerwony = problem), grupuj powiązane panele i dodawaj opisy wyjaśniające, co pokazuje każdy wykres.

### PromQL — język zapytań Prometheus

PromQL to potężny język zapytań do przeszukiwania i agregowania metryk. Podstawowe operacje to filtrowanie po labelach, obliczanie rate (tempo zmian), agregacja (sum, avg, max) i obliczanie percentyli.

Przykładowe zapytania przydatne dla startupów: rate żądań HTTP per endpoint, percentyl 95 czasu odpowiedzi, error rate jako procent wszystkich żądań, zużycie pamięci per kontener. Nauka PromQL to inwestycja, która zwraca się szybko — umiejętność pisania zapytań pozwala odpowiadać na dowolne pytania o stan systemu.

## Alerting — reagowanie na problemy

Dashboardy są bezużyteczne o 3 w nocy, gdy nikt na nie nie patrzy. Alerting automatycznie powiadamia zespół, gdy metryki przekraczają zdefiniowane progi.

### Definiowanie reguł alertów

Reguły alertów definiujesz w plikach YAML ładowanych przez Prometheus. Każda reguła zawiera wyrażenie PromQL, czas trwania (jak długo warunek musi być spełniony przed wyzwoleniem alertu), severity (critical, warning, info) i opis z kontekstem.

Kluczowe alerty dla startupu to: serwis niedostępny (probe_success == 0 przez 2 minuty), wysoki error rate (error rate > 5% przez 5 minut), wolne odpowiedzi (p95 latency > 1s przez 10 minut), wysokie zużycie zasobów (CPU > 80% przez 15 minut, dysk > 85%).

### Unikanie alert fatigue

Zbyt wiele alertów prowadzi do ignorowania ich wszystkich — to zjawisko znane jako alert fatigue. Zasady unikania: alertuj tylko na metryki wymagające natychmiastowej reakcji, używaj severity levels (critical budzi o 3 w nocy, warning czeka do rana), grupuj powiązane alerty i regularnie przeglądaj i usuwaj alerty, na które nikt nie reaguje.

### Routing alertów

Alertmanager kieruje alerty do odpowiednich kanałów na podstawie severity i labeli. Critical alerty trafiają na PagerDuty (budzi on-call), warning na dedykowany kanał Slack, info do dashboardu. Dla startupów bez formalnego on-call, Slack z dedykowanym kanałem alertów to dobry punkt wejścia.

## Trzy filary observability

Metryki to tylko jeden z trzech filarów observability. Pełny obraz wymaga też logów i traces.

### Logi z Loki

Loki to system agregacji logów od twórców Grafany, zaprojektowany do współpracy z Prometheus i Grafaną. W przeciwieństwie do ELK Stack, Loki nie indeksuje treści logów — indeksuje tylko labele (metadata), co czyni go znacznie lżejszym i tańszym w utrzymaniu.

Promtail (agent) zbiera logi z kontenerów i plików, dodaje labele (nazwa serwisu, środowisko, poziom logowania) i wysyła do Loki. W Grafanie możesz przeszukiwać logi i korelować je z metrykami na jednym dashboardzie — na przykład kliknąć na spike error rate i zobaczyć logi z tego okresu.

### Traces z Tempo

Distributed tracing śledzi żądania przez łańcuch mikroserwisów. Gdy użytkownik zgłasza, że „strona wolno się ładuje", trace pokazuje dokładnie, który serwis i które zapytanie do bazy danych jest wąskim gardłem.

Grafana Tempo to backend do przechowywania traces, integrujący się z Grafaną. Instrumentacja aplikacji za pomocą OpenTelemetry (standard branżowy) wysyła traces do Tempo. W Grafanie możesz przejść od metryki (wysoki czas odpowiedzi) przez logi (błędy w tym okresie) do trace (dokładna ścieżka żądania) — to pełna observability.

### Korelacja danych

Siła stosu Prometheus-Loki-Tempo-Grafana leży w korelacji. Z dashboardu metryk klikasz na anomalię i widzisz powiązane logi. Z logów klikasz na trace ID i widzisz pełną ścieżkę żądania. Ta korelacja dramatycznie skraca czas diagnostyki — zamiast godzin przeszukiwania logów na wielu serwerach, odpowiedź masz w minutach.

## Monitoring w pipeline CI/CD

Monitoring powinien być zintegrowany z procesem wdrażania. Po każdym deploymencie pipeline może automatycznie zweryfikować, czy kluczowe metryki nie pogorszyły się.

### Smoke testy po wdrożeniu

Po wdrożeniu nowej wersji pipeline uruchamia smoke testy — sprawdza health endpoint, wykonuje kilka kluczowych żądań API i weryfikuje, czy odpowiedzi są poprawne. Jeśli smoke testy nie przejdą, automatyczny rollback przywraca poprzednią wersję.

Integrację monitoringu z pipeline CI/CD omawiamy w artykule [GitHub Actions dla startupów](/devops/github-actions-dla-startupow/), który pokazuje, jak zautomatyzować weryfikację po wdrożeniu.

### Adnotacje deploymentów w Grafanie

Grafana pozwala dodawać adnotacje na wykresach — znaczniki czasowe z opisem. Automatyczne dodawanie adnotacji przy każdym deploymencie pozwala korelować zmiany w metrykach ze zmianami w kodzie. Gdy widzisz spike error rate, adnotacja pokazuje, że 5 minut wcześniej był deployment — to natychmiast wskazuje przyczynę.

## Bezpieczeństwo monitoringu

Monitoring zbiera wrażliwe dane o infrastrukturze i aplikacjach. Zabezpieczenie stosu monitoringu jest równie ważne jak zabezpieczenie samej aplikacji.

### Kontrola dostępu

Grafana oferuje role-based access control (RBAC) — różne poziomy dostępu dla różnych użytkowników. Developerzy widzą dashboardy swoich serwisów, management widzi przegląd, a administratorzy mają pełny dostęp. Integracja z SSO (SAML, OAuth) centralizuje zarządzanie dostępem.

### Szyfrowanie i sieć

Prometheus i Grafana powinny działać w prywatnej sieci, niedostępnej z internetu. Dostęp do Grafany przez VPN lub reverse proxy z uwierzytelnianiem. Komunikacja między komponentami powinna być szyfrowana (TLS). Metryki mogą zawierać wrażliwe informacje — nazwy endpointów, parametry zapytań, adresy IP.

Więcej o bezpieczeństwie w kontekście DevOps znajdziesz w artykule [Bezpieczeństwo pipeline DevOps](/devops/bezpieczenstwo-devops-pipeline/).

## Koszty i skalowanie

Jedną z największych zalet stosu Prometheus-Grafana jest koszt — oba narzędzia są open-source i darmowe.

### Self-hosted vs. managed

Self-hosted Prometheus i Grafana na jednej instancji EC2 (t3.medium, ~30 USD/miesiąc) wystarczają dla startupu monitorującego do 50 serwisów. Zarządzanie wymaga minimalnego wysiłku — aktualizacje, backup konfiguracji, monitoring samego monitoringu.

Grafana Cloud oferuje managed hosting z darmowym tier-em (10 000 serii metryk, 50 GB logów). Dla startupów, które nie chcą zarządzać infrastrukturą monitoringu, to atrakcyjna opcja. Płatne plany zaczynają się od 29 USD/miesiąc.

### Skalowanie Prometheus

Prometheus skaluje się wertykalnie — więcej RAM i szybszy dysk. Dla startupów z setkami serwisów, Thanos lub Cortex dodają horyzontalną skalowalność i długoterminowe przechowywanie metryk. Na wczesnym etapie to niepotrzebne — jeden Prometheus z 4 GB RAM obsłuży monitoring typowego startupu przez lata.

## Praktyczne wskazówki na start

Zacznij od monitoringu infrastruktury — Node Exporter i cAdvisor dają natychmiastowy wgląd bez zmian w kodzie aplikacji. Dodaj Blackbox Exporter do monitorowania dostępności endpointów z zewnątrz. Potem zinstrumentuj aplikację — zacznij od podstawowych metryk HTTP (liczba żądań, czas odpowiedzi, error rate).

Importuj gotowe dashboardy z Grafana.com zamiast budować od zera. Dostosuj je do swoich potrzeb po kilku tygodniach używania, gdy zrozumiesz, które metryki są najważniejsze dla Twojego systemu.

Skonfiguruj alerty od pierwszego dnia — nawet proste alerty na dostępność serwisów i error rate są lepsze niż brak alertów. Iteruj na podstawie doświadczenia — dodawaj alerty po każdym incydencie, usuwaj te, które generują szum.

Warto też zapoznać się z naszą ofertą [wdrożenia CI/CD i automatyzacji DevOps](/services/wdrozenie-ci-cd/), która obejmuje konfigurację monitoringu jako część kompleksowej automatyzacji. Jeśli szukasz wsparcia w budowie platformy observability, sprawdź [usługi observability od Devopsity](https://devopsity.com/pl/uslugi/observability/) — zespół pomoże dobrać narzędzia i skonfigurować monitoring dopasowany do Twojego systemu. Jeśli planujesz migrację do chmury, monitoring jest kluczowym elementem procesu — więcej w naszym [przewodniku po migracji do chmury](/pillars/migracja-do-chmury/).

## Podsumowanie

Prometheus i Grafana to fundament observability dla startupów — darmowe, dojrzałe i skalowalne narzędzia, które dają pełny wgląd w stan systemu. Zacznij od metryk infrastruktury, dodaj instrumentację aplikacji, skonfiguruj alerty i iteruj. Monitoring to nie projekt z datą zakończenia — to ciągły proces, który ewoluuje razem z systemem.

Kluczowe jest podejście pragmatyczne — nie próbuj monitorować wszystkiego od pierwszego dnia. Zacznij od tego, co najważniejsze (dostępność, czas odpowiedzi, error rate), i rozszerzaj w miarę potrzeb. Z czasem monitoring staje się nieodłączną częścią kultury zespołu — nikt nie wdraża zmian bez sprawdzenia dashboardu.

## Źródła

1. [Prometheus Documentation](https://prometheus.io/docs/) — oficjalna dokumentacja Prometheus.
2. [Grafana Documentation](https://grafana.com/docs/) — oficjalna dokumentacja Grafana.

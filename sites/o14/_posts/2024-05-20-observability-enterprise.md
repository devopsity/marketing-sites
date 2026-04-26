---
layout: post
title: "Observability w enterprise — metryki, logi i tracing na dużą skalę"
description: "Jak zbudować platformę observability w dużej organizacji. Trzy filary monitoringu, narzędzia open-source i strategie alertingu dla środowisk enterprise."
author: o14
date: 2024-05-20
lang: pl
content_type: post
cluster: cloud-migration
keywords:
  - "observability enterprise"
  - "monitoring enterprise"
  - "distributed tracing"
summary: "Observability to zdolność do zrozumienia wewnętrznego stanu systemu na podstawie jego zewnętrznych sygnałów — metryk, logów i śladów rozproszonych. W środowisku enterprise, gdzie dziesiątki mikroserwisów komunikują się ze sobą, observability jest warunkiem koniecznym do utrzymania niezawodności i szybkiego rozwiązywania incydentów."
faq:
  - q: "Czym różni się observability od monitoringu?"
    a: "Monitoring odpowiada na pytanie 'czy system działa?' — sprawdza znane metryki i alarmuje przy przekroczeniu progów. Observability odpowiada na pytanie 'dlaczego system nie działa?' — pozwala eksplorować nieznane problemy na podstawie danych telemetrycznych bez konieczności wcześniejszego definiowania, czego szukamy."
  - q: "Jakie narzędzia observability sprawdzają się w enterprise?"
    a: "Popularne zestawy to Prometheus + Grafana + Loki + Tempo (open-source) lub Datadog, New Relic, Dynatrace (komercyjne). Wybór zależy od budżetu, skali i kompetencji zespołu. OpenTelemetry jako standard instrumentacji pozwala zmienić backend bez modyfikacji kodu aplikacji."
definitions:
  - term: "Observability"
    definition: "Zdolność do wnioskowania o wewnętrznym stanie systemu na podstawie jego zewnętrznych sygnałów — metryk, logów i śladów rozproszonych (traces)."
  - term: "OpenTelemetry"
    definition: "Otwarty standard i zestaw narzędzi do zbierania danych telemetrycznych (metryk, logów, traces) z aplikacji, niezależny od konkretnego backendu observability."
---

## Trzy filary observability

Observability opiera się na trzech typach danych telemetrycznych, które razem dają pełny obraz zachowania systemu. Metryki mówią, co się dzieje (CPU na 95%, latencja wzrosła o 200ms). Logi mówią, dlaczego to się dzieje (błąd połączenia z bazą danych, timeout na zewnętrznym API). Ślady rozproszone (traces) mówią, gdzie to się dzieje — pokazują pełną ścieżkę żądania przez wszystkie mikroserwisy.

W małym systemie wystarczą logi. W środowisku enterprise z setkami mikroserwisów, bez korelacji między tymi trzema filarami, diagnozowanie problemów staje się jak szukanie igły w stogu siana. Dojrzała platforma observability łączy metryki, logi i traces w spójny obraz, pozwalając przejść od alertu do przyczyny źródłowej w minutach zamiast godzin.

## Metryki — fundament monitoringu

### Prometheus jako standard

Prometheus stał się de facto standardem zbierania metryk w środowiskach cloud-native. Jego model pull-based (Prometheus odpytuje aplikacje) upraszcza konfigurację, a język zapytań PromQL pozwala na zaawansowaną analizę danych. W enterprise Prometheus wymaga jednak przemyślanej architektury — pojedyncza instancja nie obsłuży setek tysięcy serii czasowych.

Rozwiązania takie jak Thanos i Cortex dodają do Prometheus długoterminowe przechowywanie danych, globalny widok z wielu klastrów i wysoką dostępność. Dla organizacji, które nie chcą zarządzać infrastrukturą metryk, Amazon Managed Prometheus i Grafana Cloud oferują zarządzane alternatywy.

### Metryki biznesowe i SLO

Metryki techniczne (CPU, pamięć, latencja) to podstawa, ale w enterprise równie ważne są metryki biznesowe — liczba transakcji, czas odpowiedzi API z perspektywy użytkownika, wskaźnik konwersji. Service Level Objectives (SLO) łączą oba światy, definiując mierzalne cele niezawodności usług.

SLO wyrażone jako error budget (np. 99.9% dostępności = 43 minuty przestoju miesięcznie) dają zespołom jasny framework decyzyjny. Gdy error budget się wyczerpuje, priorytetem staje się stabilność. Gdy jest zapas, zespół może podejmować ryzyko i wdrażać nowe funkcje szybciej.

## Logi — kontekst i szczegóły

### Centralizacja logów

W środowisku enterprise logi z setek mikroserwisów muszą trafiać do centralnego systemu, który umożliwia wyszukiwanie, filtrowanie i korelację. Popularne rozwiązania to Elasticsearch (ELK stack), Grafana Loki i CloudWatch Logs. Loki zyskuje popularność dzięki niskiemu kosztowi przechowywania — indeksuje tylko metadane (labels), a treść logów kompresuje i przechowuje w object storage.

Kluczowe jest ustandaryzowanie formatu logów w całej organizacji. Strukturyzowane logi w formacie JSON z obowiązkowymi polami (timestamp, level, service, trace_id, request_id) umożliwiają automatyczną analizę i korelację z innymi sygnałami telemetrycznymi.

### Retencja i koszty

Logi generują ogromne ilości danych — w dużej organizacji to terabajty dziennie. Polityka retencji musi balansować między potrzebami debugowania (krótkoterminowe, pełne logi) a wymaganiami compliance (długoterminowe, archiwalne). Typowe podejście to hot storage (7-30 dni, pełne wyszukiwanie), warm storage (90 dni, ograniczone wyszukiwanie) i cold storage (lata, tylko na potrzeby audytu).

## Distributed tracing — śledzenie żądań

### Jak działa tracing

Distributed tracing przypisuje unikalne ID do każdego żądania wchodzącego do systemu i propaguje je przez wszystkie mikroserwisy, które to żądanie obsługują. Każdy serwis raportuje swój fragment (span) — czas rozpoczęcia, czas trwania, status i metadane. Złożone razem, spany tworzą trace — pełny obraz ścieżki żądania przez system.

W środowisku enterprise, gdzie jedno żądanie użytkownika może przejść przez kilkanaście mikroserwisów, tracing jest niezbędny do identyfikacji wąskich gardeł i zrozumienia zależności między serwisami. Bez tracingu diagnozowanie problemów z latencją w systemie rozproszonym jest praktycznie niemożliwe.

### OpenTelemetry jako standard instrumentacji

OpenTelemetry (OTel) to otwarty standard instrumentacji aplikacji, który unifikuje zbieranie metryk, logów i traces. Zamiast integrować się z konkretnym backendem (Jaeger, Datadog, New Relic), aplikacja wysyła dane przez OTel Collector, który kieruje je do wybranego systemu.

Dla enterprise OTel daje kluczową korzyść — vendor independence. Zmiana backendu observability nie wymaga modyfikacji kodu aplikacji. To szczególnie ważne w dużych organizacjach, gdzie migracja między narzędziami to projekt na miesiące.

## Alerting — sztuka powiadamiania

Skuteczny alerting w enterprise wymaga dyscypliny. Każdy alert powinien być actionable (wymaga konkretnej reakcji), urgent (nie może czekać do rana) i skierowany do właściwego zespołu. Alerty, które nie spełniają tych kryteriów, prowadzą do alert fatigue — zespoły zaczynają ignorować powiadomienia, co prowadzi do przeoczenia prawdziwych incydentów.

Warstwowe podejście do alertingu sprawdza się najlepiej: alerty krytyczne (pager/telefon) dla problemów wpływających na użytkowników, ostrzeżenia (Slack/Teams) dla degradacji wymagających uwagi w godzinach pracy i informacyjne (dashboard) dla trendów do analizy przy okazji.

## Budowanie kultury observability

Narzędzia to tylko połowa sukcesu. Druga połowa to kultura organizacyjna, w której zespoły traktują observability jako integralną część procesu wytwórczego. Każdy nowy mikroserwis powinien od pierwszego dnia emitować metryki, strukturyzowane logi i traces. Każdy incydent powinien kończyć się blameless postmortem z konkretnymi action items dotyczącymi poprawy observability.

Budowanie takiej kultury wymaga wsparcia ze strony platformy — gotowe biblioteki instrumentacji, szablony dashboardów, dokumentacja i szkolenia. Zespół platformowy powinien dostarczać observability as a service, minimalizując barierę wejścia dla zespołów produktowych.

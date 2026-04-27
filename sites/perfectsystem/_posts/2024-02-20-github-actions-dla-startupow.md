---
layout: post
title: "GitHub Actions dla startupów — jak zbudować pipeline CI/CD"
description: "Praktyczny przewodnik po GitHub Actions dla startupów. Konfiguracja pipeline CI/CD krok po kroku — od pierwszego workflow po wdrożenie na produkcję."
author: sal
date: 2024-02-20
last_modified: 2024-03-01
lang: pl
content_type: post
cluster: devops-automation
keywords:
  - "GitHub Actions"
  - "CI/CD startup"
  - "pipeline CI/CD"
image: /assets/images/2.jpg
categories:
  - devops
tags:
  - github-actions
  - ci-cd
  - automatyzacja
backlink_target: "https://devopsity.com/pl/services/"
backlink_anchor: "wdrożenie CI/CD z Devopsity"
summary: "GitHub Actions to wbudowany w GitHub system CI/CD, który pozwala automatyzować budowanie, testowanie i wdrażanie aplikacji bezpośrednio z repozytorium. Dla startupów to najszybsza droga do profesjonalnego pipeline — darmowy tier oferuje 2000 minut miesięcznie, konfiguracja odbywa się w plikach YAML, a marketplace zawiera tysiące gotowych akcji."
faq:
  - q: "Czy GitHub Actions jest darmowy dla startupów?"
    a: "Tak, GitHub Actions oferuje 2000 darmowych minut miesięcznie dla prywatnych repozytoriów na planie Free. Dla publicznych repozytoriów minuty są nieograniczone. Plan Team (4 USD/użytkownika/miesiąc) zwiększa limit do 3000 minut."
  - q: "Jak długo trwa konfiguracja pierwszego pipeline CI/CD z GitHub Actions?"
    a: "Podstawowy pipeline budujący i testujący aplikację można skonfigurować w 1-2 godziny. Pełny pipeline z wdrożeniem na staging, skanowaniem bezpieczeństwa i deployment na produkcję to 1-3 dni pracy."
definitions:
  - term: "Workflow"
    definition: "Zautomatyzowany proces zdefiniowany w pliku YAML w katalogu .github/workflows repozytorium. Workflow składa się z jednego lub więcej jobów uruchamianych w odpowiedzi na zdarzenia takie jak push, pull request czy harmonogram."
  - term: "Runner"
    definition: "Maszyna wirtualna lub fizyczna, na której wykonywane są joby workflow. GitHub oferuje hosted runners (zarządzane przez GitHub) oraz możliwość konfiguracji self-hosted runners na własnej infrastrukturze."
sources:
  - url: "https://docs.github.com/en/actions"
    title: "GitHub Actions Documentation"
  - url: "https://github.blog/changelog/"
    title: "GitHub Changelog"
---

## Dlaczego GitHub Actions to najlepszy wybór CI/CD dla startupów

Wybór narzędzia CI/CD to jedna z pierwszych decyzji infrastrukturalnych, jakie podejmuje startup. Na rynku jest wiele opcji — Jenkins, GitLab CI, CircleCI, Travis CI — ale dla zespołów korzystających z GitHuba odpowiedź jest prosta: GitHub Actions.

Główna przewaga GitHub Actions to natywna integracja z ekosystemem GitHub. Nie musisz konfigurować webhooków, zarządzać osobnym serwisem ani synchronizować uprawnień. Pipeline jest częścią repozytorium — definiujesz go w plikach YAML, wersjonujesz razem z kodem i przeglądasz w pull requestach. Status pipeline jest widoczny bezpośrednio w interfejsie GitHub, a wyniki testów pojawiają się jako komentarze do PR.

Darmowy tier oferuje 2000 minut miesięcznie dla prywatnych repozytoriów — to wystarczy dla startupu z kilkoma developerami i kilkunastoma buildami dziennie. Dla publicznych repozytoriów open-source minuty są nieograniczone. Marketplace zawiera ponad 15 000 gotowych akcji — od budowania aplikacji Node.js po wdrażanie na AWS, skanowanie bezpieczeństwa i wysyłanie powiadomień na Slack.

Ten artykuł jest częścią naszego [kompletnego przewodnika po automatyzacji DevOps dla startupów](/pillars/automatyzacja-devops-startupy/), który omawia wszystkie filary automatyzacji — od CI/CD po monitoring i bezpieczeństwo.

## Podstawowe koncepcje GitHub Actions

Zanim zaczniesz konfigurować pipeline, warto zrozumieć kluczowe pojęcia. GitHub Actions operuje na czterech poziomach abstrakcji: workflow, job, step i action.

### Workflow, job, step, action

Workflow to najwyższy poziom — zautomatyzowany proces zdefiniowany w pliku YAML. Jeden workflow może zawierać wiele jobów. Job to zestaw kroków wykonywanych na jednym runnerze. Joby mogą działać równolegle lub sekwencyjnie (z zależnościami). Step to pojedyncza operacja w ramach joba — uruchomienie komendy shell lub wywołanie akcji. Action to reużywalny komponent — gotowy blok logiki, który możesz użyć w swoim workflow.

### Triggery — kiedy uruchamiać pipeline

Workflow uruchamia się w odpowiedzi na zdarzenia (events). Najczęstsze triggery to push (każdy push do brancha), pull_request (otwarcie lub aktualizacja PR), schedule (harmonogram cron) i workflow_dispatch (ręczne uruchomienie). Możesz filtrować triggery po branchach i ścieżkach — na przykład uruchamiać pipeline tylko przy zmianach w katalogu `src/`.

### Runners — gdzie wykonuje się pipeline

GitHub oferuje hosted runners z Ubuntu, Windows i macOS. Dla większości startupów hosted runners z Ubuntu są wystarczające i najprostsze w użyciu. Self-hosted runners mają sens, gdy potrzebujesz specyficznego hardware (GPU, ARM), dostępu do prywatnej sieci lub chcesz obniżyć koszty przy dużej liczbie buildów.

## Konfiguracja pierwszego workflow krok po kroku

Zacznijmy od praktyki. Skonfigurujemy pipeline CI dla typowej aplikacji webowej — budowanie, testy, linting i analiza bezpieczeństwa.

### Struktura pliku workflow

Pliki workflow znajdują się w katalogu `.github/workflows/` repozytorium. Każdy plik YAML to osobny workflow. Nazwa pliku nie ma znaczenia, ale warto stosować konwencję opisującą cel — na przykład `ci.yml`, `deploy-staging.yml`, `security-scan.yml`.

Podstawowa struktura pliku workflow zawiera trzy sekcje: `name` (nazwa wyświetlana w interfejsie), `on` (triggery) i `jobs` (definicje jobów). Każdy job definiuje `runs-on` (typ runnera) i `steps` (lista kroków).

### Pipeline CI — budowanie i testy

Pierwszy workflow powinien budować aplikację i uruchamiać testy przy każdym pushu i pull requeście. Dla aplikacji Node.js typowy pipeline obejmuje checkout kodu, konfigurację Node.js z cache npm, instalację zależności, uruchomienie lintingu, uruchomienie testów jednostkowych i budowanie aplikacji.

Kluczowe optymalizacje to cache zależności (skraca czas buildu o 30-60%), matrix strategy (testowanie na wielu wersjach Node.js równolegle) i fail-fast (zatrzymanie wszystkich jobów, gdy jeden zawiedzie).

### Cache i artefakty

Cache przechowuje zależności między buildami — nie musisz pobierać npm packages przy każdym uruchomieniu. Akcja `actions/cache` obsługuje to automatycznie. Artefakty to pliki generowane przez pipeline — raporty testów, coverage, zbudowana aplikacja. Akcja `actions/upload-artifact` zapisuje je, a `actions/download-artifact` pobiera w kolejnych jobach.

## Pipeline CD — automatyczne wdrażanie

Po skonfigurowaniu CI kolejnym krokiem jest automatyczne wdrażanie. Typowy setup dla startupu obejmuje automatyczne wdrożenie na staging po merge do main i manualne zatwierdzenie wdrożenia na produkcję.

### Wdrażanie na staging

Workflow deploy-staging uruchamia się po pushu do brancha `main`. Buduje obraz Docker, wypycha go do rejestru kontenerów (ECR, GHCR) i wdraża na środowisko staging. Dla aplikacji na AWS ECS to aktualizacja task definition i wymuszenie nowego deploymentu.

GitHub Environments pozwalają zdefiniować środowiska (staging, production) z oddzielnymi sekretami i regułami ochrony. Dla środowiska produkcyjnego możesz wymagać manualnego zatwierdzenia przez wyznaczone osoby przed wdrożeniem.

### Wdrażanie na produkcję

Wdrożenie na produkcję powinno wymagać manualnego zatwierdzenia. GitHub Environments z protection rules obsługują to natywnie — po wdrożeniu na staging, pipeline czeka na zatwierdzenie przez wyznaczonego reviewera. Po zatwierdzeniu ten sam obraz Docker (zbudowany i przetestowany na staging) jest wdrażany na produkcję.

To gwarantuje, że na produkcję trafia dokładnie ten sam artefakt, który był testowany na staging — nie ma ryzyka, że ponowne budowanie wprowadzi różnice.

### Rollback

Plan rollbacku jest równie ważny jak plan wdrożenia. Najprostszy rollback to wdrożenie poprzedniej wersji obrazu Docker. GitHub Actions przechowuje historię workflow runs — możesz ręcznie uruchomić ponownie poprzedni udany deployment. Dla bardziej zaawansowanych scenariuszy warto zaimplementować automatyczny rollback na podstawie health checków po wdrożeniu.

## Bezpieczeństwo w GitHub Actions

Pipeline CI/CD ma dostęp do kodu źródłowego, sekretów i infrastruktury produkcyjnej — to czyni go atrakcyjnym celem ataków. Bezpieczeństwo pipeline to temat, który omawiamy szczegółowo w artykule [Bezpieczeństwo pipeline DevOps — DevSecOps dla startupów](/devops/bezpieczenstwo-devops-pipeline/).

### Zarządzanie sekretami

GitHub Secrets przechowuje wrażliwe dane — klucze API, tokeny, hasła — w zaszyfrowanej formie. Sekrety są dostępne w workflow jako zmienne środowiskowe, ale nie pojawiają się w logach (GitHub automatycznie je maskuje). Definiuj sekrety na poziomie repozytorium lub organizacji, nigdy nie hardcoduj ich w plikach workflow.

### OIDC zamiast długoterminowych kluczy

Zamiast przechowywać klucze dostępowe AWS jako sekrety, użyj OIDC (OpenID Connect) do federacji tożsamości. GitHub Actions może uwierzytelniać się bezpośrednio z AWS, Azure czy GCP bez długoterminowych kluczy. To bezpieczniejsze — nie ma kluczy do wycieku — i prostsze w zarządzaniu.

### Skanowanie zależności i kodu

Zintegruj skanowanie bezpieczeństwa bezpośrednio w pipeline. Dependabot automatycznie tworzy PR z aktualizacjami podatnych zależności. CodeQL (darmowy dla publicznych repozytoriów) analizuje kod pod kątem podatności. Trivy skanuje obrazy Docker. Te narzędzia działają jako dodatkowe bramy jakości — pull request z krytyczną podatnością nie przejdzie code review.

## Zaawansowane wzorce i optymalizacje

Po opanowaniu podstaw warto poznać wzorce, które zwiększają efektywność pipeline i zespołu.

### Reusable workflows

Reusable workflows pozwalają zdefiniować workflow raz i wywoływać go z wielu repozytoriów. To idealne dla startupów z wieloma mikroserwisami — definiujesz standardowy pipeline CI w jednym repozytorium i reużywasz go we wszystkich projektach. Zmiany w pipeline propagują się automatycznie.

### Matrix strategy

Matrix strategy uruchamia ten sam job z różnymi kombinacjami parametrów — na przykład testowanie na Node.js 18, 20 i 22 jednocześnie. To przydatne dla bibliotek i narzędzi, które muszą wspierać wiele wersji runtime.

### Concurrency control

Concurrency groups zapobiegają równoległemu uruchamianiu wielu instancji tego samego workflow. Na przykład, jeśli pushesz dwa commity szybko po sobie, drugi workflow anuluje pierwszy zamiast czekać w kolejce. To oszczędza minuty i przyspiesza feedback.

### Composite actions

Composite actions to reużywalne bloki kroków, które możesz wydzielić do osobnych plików. Zamiast kopiować te same 10 kroków w każdym workflow, definiujesz je raz jako composite action i wywołujesz jedną linijką. To upraszcza utrzymanie i zapewnia spójność.

## Integracja z ekosystemem narzędzi

GitHub Actions dobrze integruje się z narzędziami, które omawiamy w innych artykułach tego cyklu.

### Terraform w pipeline

Infrastructure as Code z Terraform naturalnie wpasowuje się w pipeline CI/CD. Workflow może automatycznie uruchamiać `terraform plan` przy pull requeście (pokazując planowane zmiany w komentarzu do PR) i `terraform apply` po merge. Więcej o Terraform znajdziesz w artykule [Terraform dla początkujących](/devops/terraform-dla-poczatkujacych/).

### Docker build i push

Budowanie i wypychanie obrazów Docker to standardowy krok w pipeline CD. Akcja `docker/build-push-action` obsługuje multi-platform builds, cache warstw i push do wielu rejestrów jednocześnie. Integracja z Trivy dodaje skanowanie bezpieczeństwa obrazu przed pushem.

### Monitoring deploymentów

Po wdrożeniu warto automatycznie zweryfikować, czy aplikacja działa poprawnie. Pipeline może uruchomić smoke testy, sprawdzić health endpoint i zweryfikować kluczowe metryki w [Prometheus i Grafanie](/devops/monitoring-prometheus-grafana/). Jeśli weryfikacja nie przejdzie, automatyczny rollback przywraca poprzednią wersję.

## Koszty i limity GitHub Actions

Zrozumienie modelu kosztów pomaga uniknąć niespodzianek na rachunku.

### Darmowy tier

Plan Free oferuje 2000 minut miesięcznie dla prywatnych repozytoriów. Minuty na Linux runners są liczone 1:1, na Windows 2:1, a na macOS 10:1. Dla startupu z 3-5 developerami i aplikacją Node.js na Linux runners, 2000 minut to zwykle 100-200 buildów miesięcznie — wystarczająco na start.

### Optymalizacja zużycia minut

Cache zależności skraca buildy o 30-60%. Concurrency control eliminuje zbędne buildy. Path filters uruchamiają pipeline tylko przy zmianach w odpowiednich katalogach. Conditional steps pomijają kosztowne operacje, gdy nie są potrzebne (na przykład budowanie obrazu Docker tylko przy merge do main, nie przy każdym PR).

### Kiedy rozważyć self-hosted runners

Gdy miesięczne zużycie przekracza 5000-10000 minut, self-hosted runners mogą być tańsze. Instancja EC2 t3.medium kosztuje około 30 USD miesięcznie i oferuje nieograniczone minuty. Wymaga jednak administracji — aktualizacje, bezpieczeństwo, skalowanie. Dla startupów z dużą liczbą buildów to opłacalna inwestycja.

## Praktyczne wskazówki na start

Kilka rekomendacji z doświadczenia wdrażania GitHub Actions w startupach. Zacznij od prostego pipeline CI — budowanie i testy. Nie próbuj od razu wdrożyć pełnego CD z canary releases i automatycznym rollbackiem. Dodawaj kolejne elementy iteracyjnie, gdy poprzednie działają stabilnie.

Używaj oficjalnych akcji GitHub (actions/checkout, actions/setup-node, actions/cache) zamiast akcji od zewnętrznych autorów, gdy to możliwe. Oficjalne akcje są lepiej utrzymywane i bezpieczniejsze. Dla akcji zewnętrznych pinuj wersje po SHA commita, nie po tagu — tagi mogą być nadpisane.

Dokumentuj workflow w komentarzach YAML. Za trzy miesiące nie będziesz pamiętać, dlaczego dodałeś ten konkretny krok. Komentarz wyjaśniający „dlaczego" (nie „co") oszczędza godziny debugowania.

Jeśli potrzebujesz wsparcia w konfiguracji pipeline CI/CD, rozważ [wdrożenie CI/CD z Devopsity](https://devopsity.com/pl/services/) — zespół specjalistów pomoże zaprojektować i wdrożyć pipeline dopasowany do potrzeb Twojego startupu, od prostego CI po pełny CD z automatycznym rollbackiem.

Warto też zapoznać się z naszą ofertą [wdrożenia CI/CD i automatyzacji DevOps](/services/wdrozenie-ci-cd/), która obejmuje kompleksową konfigurację pipeline, Infrastructure as Code i monitoring.

## Podsumowanie

GitHub Actions to najprostszy sposób na profesjonalny pipeline CI/CD dla startupu korzystającego z GitHuba. Darmowy tier wystarcza na start, konfiguracja jest prosta, a ekosystem gotowych akcji pokrywa większość potrzeb. Zacznij od budowania i testów, dodaj automatyczne wdrażanie na staging, a potem rozszerzaj o bezpieczeństwo, monitoring i zaawansowane strategie wdrażania.

Kluczowe jest podejście iteracyjne — nie próbuj zbudować idealnego pipeline od pierwszego dnia. Każdy dodany krok automatyzacji eliminuje konkretny rodzaj ręcznej pracy i zmniejsza ryzyko błędu. Z czasem pipeline staje się niezawodnym fundamentem, na którym zespół buduje i wdraża oprogramowanie z pewnością i szybkością.

## Źródła

1. [GitHub Actions Documentation](https://docs.github.com/en/actions) — oficjalna dokumentacja GitHub Actions.
2. [GitHub Changelog](https://github.blog/changelog/) — najnowsze zmiany i funkcje w GitHub Actions.

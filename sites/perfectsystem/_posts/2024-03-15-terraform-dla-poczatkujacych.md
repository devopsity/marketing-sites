---
layout: post
title: "Terraform dla początkujących — Infrastructure as Code w praktyce"
description: "Praktyczny przewodnik po Terraform dla startupów. Podstawy Infrastructure as Code, konfiguracja AWS, moduły i najlepsze praktyki zarządzania infrastrukturą jako kodem."
author: george
date: 2024-03-15
last_modified: 2024-04-01
lang: pl
content_type: post
cluster: devops-automation
keywords:
  - "Terraform"
  - "Infrastructure as Code"
  - "IaC startup"
image: /assets/images/3.jpg
categories:
  - devops
tags:
  - terraform
  - iac
  - aws
backlink_target: "https://devopsity.com/pl/uslugi/konsulting/"
backlink_anchor: "konsulting DevOps od Devopsity"
summary: "Terraform to narzędzie Infrastructure as Code od HashiCorp, które pozwala definiować infrastrukturę chmurową w plikach konfiguracyjnych zamiast klikać w konsoli. Dla startupów oznacza to powtarzalną, audytowalną i wersjonowaną infrastrukturę — nowe środowisko powstaje w minuty, a każda zmiana przechodzi przez code review."
faq:
  - q: "Czy Terraform jest darmowy?"
    a: "Tak, Terraform CLI jest open-source i darmowy. Terraform Cloud oferuje darmowy tier dla małych zespołów (do 5 użytkowników) z remote state management i podstawowymi funkcjami współpracy. Płatne plany zaczynają się od 20 USD/użytkownika/miesiąc."
  - q: "Ile czasu zajmuje nauka Terraform od zera?"
    a: "Podstawy Terraform — składnia HCL, providers, resources, state — można opanować w 1-2 tygodnie. Zaawansowane tematy jak moduły, workspaces i zarządzanie state w zespole wymagają 1-2 miesięcy praktyki. Kluczowe jest uczenie się na realnych projektach, nie tylko z tutoriali."
definitions:
  - term: "HCL (HashiCorp Configuration Language)"
    definition: "Deklaratywny język konfiguracyjny używany przez Terraform do definiowania infrastruktury. HCL opisuje pożądany stan zasobów, a Terraform oblicza i wykonuje zmiany potrzebne do osiągnięcia tego stanu."
  - term: "Terraform State"
    definition: "Plik JSON przechowujący aktualny stan zarządzanej infrastruktury. State pozwala Terraform porównać pożądany stan (kod) z rzeczywistym stanem zasobów i obliczyć wymagane zmiany."
sources:
  - url: "https://developer.hashicorp.com/terraform/docs"
    title: "Terraform Documentation"
  - url: "https://developer.hashicorp.com/terraform/tutorials"
    title: "Terraform Tutorials"
---

## Czym jest Terraform i dlaczego startupy powinny go używać

Terraform to narzędzie Infrastructure as Code (IaC) od HashiCorp, które pozwala definiować, wdrażać i zarządzać infrastrukturą chmurową za pomocą plików konfiguracyjnych. Zamiast klikać w konsoli AWS, Azure czy GCP, opisujesz zasoby w kodzie — sieci, serwery, bazy danych, uprawnienia — a Terraform tworzy je automatycznie.

Dla startupów Terraform rozwiązuje trzy fundamentalne problemy. Po pierwsze, powtarzalność — środowisko staging jest identyczne z produkcją, bo powstaje z tego samego kodu. Po drugie, audytowalność — każda zmiana w infrastrukturze jest widoczna w historii Git, z autorem, datą i opisem. Po trzecie, odtwarzalność — gdy coś pójdzie nie tak, możesz odtworzyć całą infrastrukturę od zera w minuty zamiast dni.

Bez IaC startup z trzema środowiskami (dev, staging, produkcja) ma trzy ręcznie skonfigurowane zestawy zasobów, które z czasem się rozjeżdżają. Nikt nie pamięta, dlaczego security group na produkcji ma inną regułę niż na staging. Terraform eliminuje ten problem — infrastruktura jest kodem, a kod jest źródłem prawdy. Podejście [zarządzanej infrastruktury chmurowej](https://devopsity.com/pl/uslugi/chmura-pod-kontrola/) pozwala zespołom skupić się na produkcie zamiast na gaszeniu pożarów.

Ten artykuł jest częścią naszego [kompletnego przewodnika po automatyzacji DevOps dla startupów](/pillars/automatyzacja-devops-startupy/), który omawia wszystkie filary automatyzacji — od CI/CD po bezpieczeństwo pipeline.

## Podstawy Terraform — pierwsze kroki

Zanim zaczniesz pisać kod Terraform, musisz zrozumieć kilka kluczowych koncepcji: providers, resources, data sources, variables, outputs i state.

### Providers — łączniki z chmurą

Provider to plugin, który pozwala Terraform komunikować się z konkretnym dostawcą usług. Provider AWS umożliwia zarządzanie zasobami AWS, provider Azure — zasobami Azure, a provider Kubernetes — obiektami K8s. Terraform Registry zawiera ponad 3000 providerów — od głównych chmur po narzędzia takie jak GitHub, Datadog czy Cloudflare.

Konfiguracja providera AWS wymaga określenia regionu i metody uwierzytelniania. Dla lokalnego developmentu używasz profilu AWS CLI, a w pipeline CI/CD — OIDC lub zmiennych środowiskowych z kluczami dostępowymi.

### Resources — budulce infrastruktury

Resource to pojedynczy zasób infrastruktury — instancja EC2, bucket S3, baza RDS, reguła security group. Każdy resource ma typ (np. `aws_instance`, `aws_s3_bucket`), nazwę logiczną (używaną w kodzie Terraform) i zestaw argumentów definiujących jego konfigurację.

Terraform operuje deklaratywnie — opisujesz pożądany stan, a Terraform oblicza, jakie operacje są potrzebne, aby go osiągnąć. Jeśli resource nie istnieje, Terraform go tworzy. Jeśli istnieje, ale ma inną konfigurację, Terraform go aktualizuje. Jeśli istnieje w state, ale nie w kodzie, Terraform go usuwa.

### Variables i outputs

Variables parametryzują konfigurację — zamiast hardcodować rozmiar instancji, definiujesz zmienną `instance_type` z wartością domyślną i nadpisujesz ją per środowisko. Outputs eksportują wartości z jednego modułu do użycia w innym — na przykład ID VPC utworzonego przez moduł sieciowy jest używany przez moduł compute.

## Struktura projektu Terraform dla startupu

Dobrze zorganizowany projekt Terraform to fundament skalowalnej infrastruktury. Dla startupów rekomendujemy modularną strukturę z oddzielnymi katalogami per środowisko i reużywalnymi modułami.

### Moduły — reużywalny kod infrastruktury

Moduł to zestaw plików Terraform zgrupowanych w katalogu, które razem tworzą logiczną jednostkę infrastruktury. Moduł `networking` tworzy VPC, subnety i routing. Moduł `database` tworzy instancję RDS z security group i parametrami. Moduł `compute` tworzy klaster ECS z task definitions i load balancerem.

Moduły pozwalają na reużycie — ten sam moduł `database` tworzy bazę na dev (mała instancja, bez replikacji) i na produkcji (duża instancja, Multi-AZ, automatyczne backupy). Różnica to tylko parametry wejściowe.

### Środowiska — dev, staging, produkcja

Każde środowisko ma własny katalog z plikami konfiguracyjnymi, które wywołują wspólne moduły z odpowiednimi parametrami. Terragrunt upraszcza tę strukturę, eliminując duplikację konfiguracji backendu i providera między środowiskami.

Kluczowa zasada — środowiska powinny być jak najbardziej identyczne. Różnice powinny ograniczać się do rozmiaru zasobów (mniejsze instancje na dev), liczby replik i konfiguracji dostępu. Im bardziej staging przypomina produkcję, tym mniej niespodzianek przy wdrożeniu.

### Remote state — współpraca w zespole

Terraform state przechowuje aktualny stan infrastruktury. Domyślnie state jest zapisywany lokalnie, co uniemożliwia współpracę w zespole. Remote state backend — S3 z DynamoDB locking dla AWS — przechowuje state centralnie i zapobiega równoczesnym modyfikacjom.

Konfiguracja remote state to jeden z pierwszych kroków przy wdrażaniu Terraform w zespole. Bez niego dwóch developerów uruchamiających `terraform apply` jednocześnie może uszkodzić infrastrukturę.

## Praktyczny przykład — infrastruktura aplikacji webowej na AWS

Przejdźmy do praktyki. Zbudujemy infrastrukturę dla typowej aplikacji webowej startupu: VPC z subnetami, klaster ECS z Fargate, baza danych RDS PostgreSQL, bucket S3 na pliki statyczne i CloudFront jako CDN.

### Sieć — VPC i subnety

Moduł sieciowy tworzy VPC z publicznymi i prywatnymi subnetami w dwóch strefach dostępności. Publiczne subnety hostują load balancer i NAT Gateway. Prywatne subnety hostują aplikację i bazę danych — nie mają bezpośredniego dostępu z internetu.

Terraform pozwala zdefiniować tę strukturę w kilkudziesięciu liniach kodu. Ręczna konfiguracja przez konsolę AWS wymagałaby kilkudziesięciu kliknięć i łatwo o pomyłkę — na przykład zapomnienie o route table dla prywatnego subnetu.

### Compute — ECS z Fargate

ECS (Elastic Container Service) z Fargate to rekomendowany sposób uruchamiania kontenerów na AWS dla startupów. Fargate eliminuje konieczność zarządzania instancjami EC2 — płacisz tylko za zasoby zużywane przez kontenery.

Moduł compute definiuje klaster ECS, task definition (obraz Docker, zasoby CPU/RAM, zmienne środowiskowe), service (liczba replik, strategia wdrażania) i Application Load Balancer z health checkami.

### Baza danych — RDS PostgreSQL

Moduł bazodanowy tworzy instancję RDS PostgreSQL w prywatnym subnecie, z automatycznymi backupami, szyfrowaniem at rest i security group ograniczającą dostęp tylko do aplikacji. Dla produkcji włączamy Multi-AZ (automatyczny failover) i zwiększamy rozmiar instancji.

### Storage i CDN

Bucket S3 przechowuje pliki statyczne i uploady użytkowników. CloudFront dystrybuuje je globalnie z niską latencją. Terraform konfiguruje origin access identity, aby pliki S3 były dostępne tylko przez CloudFront, nie bezpośrednio.

## Terraform w pipeline CI/CD

Terraform naturalnie integruje się z pipeline CI/CD. Automatyzacja zmian infrastrukturalnych eliminuje ryzyko ręcznych błędów i zapewnia, że każda zmiana przechodzi przez code review.

### Plan w pull requeście

Przy otwarciu pull requesta z zmianami w plikach Terraform, pipeline automatycznie uruchamia `terraform plan` i dodaje wynik jako komentarz do PR. Reviewer widzi dokładnie, jakie zasoby zostaną utworzone, zmienione lub usunięte — zanim zmiana zostanie zatwierdzona.

To kluczowa praktyka bezpieczeństwa. Bez niej developer może przypadkowo usunąć bazę danych produkcyjną jedną zmianą w kodzie. Z planem w PR, taka zmiana jest widoczna i wymaga świadomego zatwierdzenia.

Integrację Terraform z GitHub Actions omawiamy szczegółowo w artykule [GitHub Actions dla startupów](/devops/github-actions-dla-startupow/).

### Apply po merge

Po zatwierdzeniu i merge pull requesta, pipeline uruchamia `terraform apply` z zatwierdzonym planem. Zmiana jest wdrażana automatycznie, bez ręcznej interwencji. Dla środowiska produkcyjnego warto dodać dodatkowy krok zatwierdzenia (GitHub Environments z protection rules).

### Drift detection

Drift to sytuacja, gdy rzeczywisty stan infrastruktury różni się od stanu zdefiniowanego w kodzie — na przykład ktoś zmienił security group przez konsolę AWS. Regularny `terraform plan` w pipeline (np. raz dziennie) wykrywa drift i powiadamia zespół. To zapobiega sytuacji, w której „infrastruktura jako kod" staje się fikcją, bo połowa zmian jest robiona ręcznie.

## Najczęstsze błędy początkujących

Na podstawie doświadczeń z wdrażaniem Terraform w startupach, oto pułapki, które warto znać od początku.

### Brak remote state od pierwszego dnia

Lokalny state działa dla jednej osoby, ale w zespole prowadzi do konfliktów i uszkodzenia infrastruktury. Skonfiguruj remote state (S3 + DynamoDB) zanim drugi developer zacznie pracować z Terraform. To 15 minut konfiguracji, które oszczędzają godziny debugowania.

### Zbyt duży state

Jeden monolityczny state z całą infrastrukturą to problem — `terraform plan` trwa minuty, a błąd w jednym zasobie blokuje zmiany we wszystkich. Dziel state na logiczne jednostki — sieć, compute, bazy danych, monitoring. Każda jednostka ma własny state i może być zmieniana niezależnie.

### Hardcodowane wartości

Hardcodowanie regionu, rozmiaru instancji czy nazwy bucketu w kodzie uniemożliwia reużycie między środowiskami. Używaj zmiennych dla wszystkiego, co może się różnić między środowiskami. Wartości domyślne w zmiennych upraszczają konfigurację dev, a nadpisania w plikach `.tfvars` konfigurują staging i produkcję.

### Ignorowanie terraform plan

Uruchamianie `terraform apply` bez wcześniejszego przejrzenia planu to ryzyko. Plan pokazuje dokładnie, co się zmieni — ile zasobów zostanie utworzonych, zmienionych i (co najważniejsze) usuniętych. Zawsze przeglądaj plan przed apply, szczególnie na produkcji.

## Terraform a migracja do chmury

Dla startupów migrujących do chmury Terraform jest szczególnie wartościowy. Zamiast ręcznie konfigurować zasoby w konsoli AWS podczas migracji, definiujesz je w kodzie od pierwszego dnia. To oznacza, że infrastruktura jest udokumentowana, powtarzalna i łatwa do odtworzenia.

Jeśli planujesz migrację do chmury, zapoznaj się z naszym [przewodnikiem po migracji do chmury dla startupów](/pillars/migracja-do-chmury/), który omawia strategie, koszty i najlepsze praktyki. Terraform jest kluczowym narzędziem w każdej z opisanych tam strategii migracji.

Warto też przeczytać artykuł o [migracji do AWS](/chmura/migracja-do-aws/), który pokazuje praktyczne zastosowanie Terraform w kontekście konkretnego dostawcy chmurowego.

## Zaawansowane tematy — co dalej

Po opanowaniu podstaw Terraform warto poznać zaawansowane funkcje, które zwiększają produktywność i bezpieczeństwo.

### Terraform Cloud i Terraform Enterprise

Terraform Cloud oferuje remote execution (plan i apply uruchamiane na serwerach HashiCorp), policy as code (Sentinel — reguły wymuszające standardy), cost estimation (szacowanie kosztów zmian przed apply) i private module registry (wewnętrzny katalog modułów). Darmowy tier wystarcza dla małych zespołów.

### Testowanie infrastruktury

Terratest (Go) i Kitchen-Terraform (Ruby) pozwalają pisać testy automatyczne dla modułów Terraform. Test tworzy infrastrukturę, weryfikuje jej stan i usuwa ją. To szczególnie wartościowe dla modułów reużywanych w wielu projektach — test gwarantuje, że zmiana w module nie zepsuje istniejących wdrożeń.

### Import istniejących zasobów

Jeśli masz zasoby utworzone ręcznie przez konsolę, `terraform import` pozwala je „zaimportować" do state i zarządzać nimi kodem. To przydatne przy stopniowym przechodzeniu z ręcznej konfiguracji na IaC — nie musisz odtwarzać infrastruktury od zera.

Jeśli potrzebujesz wsparcia w wdrożeniu Terraform lub migracji istniejącej infrastruktury do IaC, skorzystaj z [konsulting DevOps od Devopsity](https://devopsity.com/pl/uslugi/konsulting/) — zespół specjalistów pomoże zaprojektować strukturę modułów, skonfigurować remote state i zintegrować Terraform z pipeline CI/CD.

## Podsumowanie

Terraform to fundament nowoczesnej infrastruktury dla startupów. Definiowanie zasobów jako kod eliminuje ręczną konfigurację, zapewnia powtarzalność środowisk i daje pełną audytowalność zmian. Krzywa uczenia jest łagodna — podstawy opanujesz w tydzień, a zaawansowane wzorce w ciągu kilku miesięcy praktyki.

Zacznij od prostego projektu — VPC, jedna instancja, jedna baza danych. Dodawaj moduły i środowiska iteracyjnie. Skonfiguruj remote state od pierwszego dnia. Zintegruj z pipeline CI/CD. I pamiętaj — najlepsza infrastruktura to taka, którą możesz odtworzyć od zera jednym poleceniem.

## Źródła

1. [Terraform Documentation](https://developer.hashicorp.com/terraform/docs) — oficjalna dokumentacja Terraform.
2. [Terraform Tutorials](https://developer.hashicorp.com/terraform/tutorials) — interaktywne tutoriale od HashiCorp.

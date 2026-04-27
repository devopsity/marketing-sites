---
layout: post
title: "Koszty chmury dla startupów — jak nie przepłacić w AWS, Azure i GCP"
description: "Praktyczny przewodnik po kosztach chmury dla startupów. Porównanie cenników AWS, Azure i GCP, strategie optymalizacji i najczęstsze pułapki kosztowe."
author: george
date: 2024-03-01
lang: pl
content_type: post
cluster: cloud-migration
keywords:
  - "koszty chmury startup"
  - "AWS koszty"
  - "optymalizacja kosztów chmury"
categories:
  - chmura
tags:
  - koszty
  - aws
  - optymalizacja
backlink_target: "https://devopsity.com/pl/uslugi/finops/"
backlink_anchor: "optymalizacja kosztów chmury z Devopsity"
summary: "Koszty chmury to jeden z najczęstszych powodów wahania startupów przed migracją. W rzeczywistości chmura jest tańsza niż infrastruktura on-premise, ale wymaga aktywnego zarządzania kosztami. Ten artykuł porównuje cenniki AWS, Azure i GCP, omawia strategie optymalizacji i wskazuje najczęstsze pułapki kosztowe."
faq:
  - q: "Ile kosztuje chmura dla startupu miesięcznie?"
    a: "Typowy startup z aplikacją webową, bazą danych i podstawowym monitoringiem płaci 200-2000 PLN miesięcznie w zależności od ruchu i architektury. Programy kredytowe (AWS Activate, Azure for Startups) mogą pokryć te koszty przez pierwsze 1-2 lata."
  - q: "Który dostawca chmury jest najtańszy?"
    a: "Nie ma jednoznacznej odpowiedzi — ceny zależą od konkretnych usług i wzorców użycia. AWS jest zazwyczaj najtańszy dla compute (dzięki Spot Instances), GCP dla transferu danych, a Azure oferuje najlepsze rabaty dla firm korzystających z licencji Microsoft."
definitions:
  - term: "Spot Instance"
    definition: "Instancja obliczeniowa w AWS dostępna z rabatem do 90% w porównaniu z ceną on-demand, w zamian za możliwość przerwania jej przez AWS z 2-minutowym wyprzedzeniem gdy pojawi się zapotrzebowanie na zasoby."
  - term: "Reserved Instance"
    definition: "Zobowiązanie do korzystania z określonego typu instancji przez 1 lub 3 lata w zamian za rabat 30-72% w porównaniu z ceną on-demand."
  - term: "FinOps"
    definition: "Praktyka zarządzania kosztami chmury łącząca finanse, technologię i biznes w celu maksymalizacji wartości z inwestycji chmurowych."
sources:
  - url: "https://aws.amazon.com/pricing/"
    title: "AWS Pricing"
  - url: "https://azure.microsoft.com/en-us/pricing/"
    title: "Azure Pricing"
  - url: "https://cloud.google.com/pricing"
    title: "Google Cloud Pricing"
  - url: "https://www.finops.org/introduction/what-is-finops/"
    title: "FinOps Foundation — What is FinOps"
---

## Ile naprawdę kosztuje chmura dla startupu

Zanim przejdziemy do konkretnych liczb, warto zrozumieć fundamentalną różnicę między modelem on-premise a chmurowym. W modelu tradycyjnym płacisz z góry za serwery, które mogą być wykorzystane w 10-20% — resztę mocy obliczeniowej marnujesz. W chmurze płacisz za to, czego faktycznie używasz, i skalujesz zasoby w górę lub w dół w zależności od potrzeb.

Typowy startup z aplikacją webową, bazą danych PostgreSQL i podstawowym monitoringiem płaci 200-2000 PLN miesięcznie. Dokładna kwota zależy od ruchu, rozmiaru bazy danych i wybranej architektury. Programy kredytowe — AWS Activate (do 100 000 USD), Azure for Startups (do 150 000 USD) i Google for Startups (do 200 000 USD) — mogą pokryć te koszty przez pierwsze 1-2 lata.

Jeśli dopiero zaczynasz przygodę z chmurą, zapoznaj się z naszym [kompletnym przewodnikiem po migracji do chmury](/pillars/migracja-do-chmury/), który omawia strategie i dostawców od podstaw.

## Porównanie cenników — AWS vs Azure vs GCP

### Compute — serwery wirtualne

Compute to zazwyczaj największa pozycja na rachunku chmurowym. Porównanie cen dla instancji ogólnego przeznaczenia (2 vCPU, 8 GB RAM) w regionie europejskim: AWS t3.large kosztuje około 0,0832 USD/h, Azure B2ms to około 0,0832 USD/h, a GCP e2-standard-2 to około 0,0778 USD/h. Różnice są minimalne przy cenach on-demand.

Prawdziwe oszczędności pojawiają się przy zobowiązaniach. AWS Savings Plans oferują do 72% rabatu za 3-letnie zobowiązanie. Azure Reserved VM Instances dają do 72% rabatu. GCP Committed Use Discounts oferują do 57% rabatu. Dodatkowo AWS Spot Instances i GCP Preemptible VMs dają do 90% rabatu dla obciążeń tolerujących przerwy.

### Bazy danych zarządzane

Zarządzane bazy danych eliminują konieczność administracji, ale kosztują więcej niż self-hosted. AWS RDS PostgreSQL (db.t3.medium, 2 vCPU, 4 GB RAM) to około 70 USD/miesięcznie. Azure Database for PostgreSQL Flexible Server w porównywalnej konfiguracji kosztuje około 65 USD/miesięcznie. Google Cloud SQL for PostgreSQL to około 75 USD/miesięcznie.

Do tego dochodzą koszty storage — zazwyczaj 0,10-0,15 USD/GB/miesiąc — i backupów. Szczegóły migracji baz danych omawiamy w artykule o [migracji baz danych do chmury](/chmura/migracja-bazy-danych-do-chmury/).

### Storage obiektowy

S3 (AWS), Azure Blob Storage i Google Cloud Storage oferują porównywalne ceny za storage standardowy: 0,021-0,023 USD/GB/miesiąc. Różnice pojawiają się w kosztach operacji (PUT, GET) i transferu danych.

### Transfer danych — ukryta pułapka

Transfer danych wychodzących (egress) to najczęstsza pułapka kosztowa. AWS i Azure pobierają 0,09 USD/GB za pierwsze 10 TB/miesiąc. GCP jest tańszy — 0,08 USD/GB. Dla startupu z dużym ruchem to może być znacząca pozycja. Używaj CDN (CloudFront, Azure CDN, Cloud CDN) do cachowania treści statycznych — to drastycznie redukuje koszty transferu.

## Strategie optymalizacji kosztów

### Right-sizing — nie przepłacaj za zasoby

Najczęstszy błąd to provisionowanie zbyt dużych instancji. Monitoruj wykorzystanie CPU i pamięci przez [Prometheus i Grafana](/devops/monitoring-prometheus-grafana/) i dostosowuj rozmiary instancji do rzeczywistego zapotrzebowania. AWS Compute Optimizer, Azure Advisor i GCP Recommender automatycznie sugerują optymalne rozmiary.

### Automatyczne skalowanie

Auto Scaling Groups (AWS), Virtual Machine Scale Sets (Azure) i Managed Instance Groups (GCP) automatycznie dodają i usuwają instancje w zależności od obciążenia. W połączeniu z metrykami z monitoringu, auto-scaling zapewnia, że płacisz tylko za zasoby, których faktycznie potrzebujesz.

### Wyłączanie środowisk dev/staging

Środowiska deweloperskie i testowe nie muszą działać 24/7. Automatyczne wyłączanie poza godzinami pracy (np. 18:00-8:00 i weekendy) redukuje koszty tych środowisk o 65-70%. Narzędzia takie jak AWS Instance Scheduler lub proste skrypty w [Terraform](/devops/terraform-dla-poczatkujacych/) automatyzują ten proces.

### Programy kredytowe dla startupów

Wszystkich trzech dostawców oferuje hojne programy kredytowe. AWS Activate daje od 1 000 do 100 000 USD w zależności od etapu rozwoju i powiązania z akceleratorem. Azure for Startups oferuje do 150 000 USD kredytów plus darmowe licencje na narzędzia Microsoft. Google for Startups Cloud Program daje do 200 000 USD kredytów przez 2 lata.

Aplikuj do wszystkich trzech programów — nawet jeśli używasz głównie jednego dostawcy, kredyty u pozostałych przydadzą się do testów i porównań.

## Narzędzia do monitorowania kosztów

### Natywne narzędzia dostawców

AWS Cost Explorer, Azure Cost Management i GCP Billing Reports to podstawowe narzędzia do analizy kosztów. Konfiguruj budżety z alertami — ustaw próg na 80% i 100% planowanego budżetu miesięcznego, aby uniknąć niespodzianek.

### Tagowanie zasobów

Tagowanie to fundament zarządzania kosztami. Każdy zasób powinien mieć tagi: environment (dev/staging/prod), team, project, cost-center. Tagi pozwalają alokować koszty do konkretnych zespołów i projektów, identyfikować nieużywane zasoby i śledzić trendy kosztowe.

Wdrożenie tagowania od pierwszego dnia to jedna z najlepszych inwestycji w zarządzanie kosztami. Wymuszaj tagowanie przez polityki — [Infrastructure as Code z Terraform](/devops/terraform-dla-poczatkujacych/) pozwala definiować obowiązkowe tagi na poziomie modułów.

### FinOps jako praktyka

FinOps to nie narzędzie, a praktyka organizacyjna. Łączy finanse, technologię i biznes w celu maksymalizacji wartości z inwestycji chmurowych. Dla startupu oznacza to: regularne przeglądy kosztów (co tydzień), jasne przypisanie odpowiedzialności za koszty do zespołów i ciągłą optymalizację.

## Najczęstsze pułapki kosztowe

### Zapomniane zasoby

Instancje testowe, snapshoty, nieużywane Elastic IP, puste load balancery — te zasoby generują koszty nawet gdy nikt z nich nie korzysta. Regularny audyt zasobów (co miesiąc) pozwala identyfikować i usuwać marnotrawstwo.

### Overprovisioning baz danych

Bazy danych to często druga największa pozycja kosztowa. Provisionowanie instancji Multi-AZ z dużym storage dla środowiska dev to klasyczny błąd. Używaj mniejszych instancji dla środowisk nieprodukcyjnych i Single-AZ dla dev/staging.

### Brak automatyzacji

Ręczne zarządzanie zasobami prowadzi do zapominania o wyłączaniu, nieprawidłowego rozmiaru i braku spójności. Automatyzacja przez [CI/CD](/devops/github-actions-dla-startupow/) i IaC eliminuje te problemy.

## Kiedy warto zainwestować w optymalizację

Dla startupu wydającego poniżej 1000 PLN miesięcznie na chmurę, zaawansowana optymalizacja nie ma sensu — czas inżynierów jest droższy niż potencjalne oszczędności. Skup się na podstawach: right-sizing, wyłączanie dev/staging, programy kredytowe.

Gdy rachunki przekraczają 5000 PLN miesięcznie, warto zainwestować w systematyczne podejście do FinOps. [Devopsity pomaga startupom w optymalizacji kosztów chmury](https://devopsity.com/pl/uslugi/finops/) — od audytu obecnych wydatków po wdrożenie automatyzacji i procesów FinOps.

Przy rachunkach powyżej 20 000 PLN miesięcznie Reserved Instances i Savings Plans stają się opłacalne. Zobowiązanie na 1 rok daje 30-40% oszczędności, a na 3 lata — do 72%.

## Podsumowanie

Chmura nie jest droga — droga jest źle zarządzana chmura. Kluczem do kontroli kosztów jest: monitorowanie od pierwszego dnia, tagowanie wszystkich zasobów, automatyzacja provisionowania i wyłączania, korzystanie z programów kredytowych i regularne przeglądy wydatków. Więcej o strategiach migracji i architekturze chmurowej znajdziesz w naszym [przewodniku po migracji do chmury](/pillars/migracja-do-chmury/) oraz w artykule o [migracji do AWS](/chmura/migracja-do-aws/).

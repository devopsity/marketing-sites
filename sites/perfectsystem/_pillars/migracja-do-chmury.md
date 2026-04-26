---
layout: pillar
title: "Kompletny przewodnik po migracji do chmury dla startupów"
description: "Wszystko o migracji do chmury dla startupów — strategie, koszty, narzędzia i najlepsze praktyki. Przewodnik krok po kroku."
author: sal
date: 2024-01-01
last_modified: 2024-03-01
lang: pl
content_type: pillar
cluster: cloud-migration
keywords:
  - "migracja do chmury"
  - "cloud migration"
  - "migracja chmurowa startup"
image: /assets/images/1.jpg
summary: "Migracja do chmury to strategiczny proces przenoszenia danych, aplikacji i infrastruktury IT z serwerów lokalnych do środowiska chmurowego. Dla startupów oznacza to szansę na szybsze skalowanie, niższe koszty początkowe i dostęp do zaawansowanych usług bez budowania własnego data center. W tym przewodniku omawiamy wszystkie kluczowe aspekty migracji — od wyboru dostawcy po optymalizację kosztów."
faq:
  - q: "Co to jest migracja do chmury?"
    a: "Migracja do chmury to proces przenoszenia zasobów IT — aplikacji, baz danych, serwerów i danych — z infrastruktury on-premise do usług chmurowych takich jak AWS, Azure czy Google Cloud Platform."
  - q: "Ile kosztuje migracja do chmury dla startupu?"
    a: "Koszt migracji zależy od rozmiaru infrastruktury i złożoności aplikacji. Dla typowego startupu z kilkoma mikroserwisami koszt wynosi od 5 000 do 30 000 PLN, wliczając planowanie, wykonanie i testy."
  - q: "Jak długo trwa migracja do chmury?"
    a: "Czas migracji zależy od strategii i skali. Proste przeniesienie (lift and shift) może zająć 2-4 tygodnie, natomiast pełna modernizacja aplikacji cloud-native to proces trwający 2-6 miesięcy."
  - q: "Która chmura jest najlepsza dla startupu — AWS, Azure czy GCP?"
    a: "Wybór zależy od potrzeb. AWS oferuje najszerszy ekosystem usług, Azure dobrze integruje się z narzędziami Microsoft, a GCP wyróżnia się w obszarze danych i machine learning. Dla większości startupów AWS jest bezpiecznym wyborem ze względu na dojrzałość platformy."
  - q: "Czy migracja do chmury jest bezpieczna?"
    a: "Tak, pod warunkiem prawidłowego wdrożenia. Dostawcy chmurowi oferują zaawansowane mechanizmy bezpieczeństwa — szyfrowanie, IAM, monitoring. Kluczowe jest poprawne skonfigurowanie uprawnień i regularne audyty bezpieczeństwa."
devopsity_translations:
  en: "https://devopsity.com/cloud-migration-guide/"
  pl: "https://devopsity.com/pl/przewodnik-migracja-chmura/"
definitions:
  - term: "Lift and Shift"
    definition: "Strategia migracji polegająca na przeniesieniu aplikacji do chmury bez zmian w architekturze. Najszybsza metoda, ale nie wykorzystuje w pełni możliwości chmury."
  - term: "Cloud-Native"
    definition: "Podejście do budowania aplikacji zaprojektowanych specjalnie dla środowiska chmurowego, wykorzystujących kontenery, mikroserwisy i orkiestrację."
  - term: "IaC (Infrastructure as Code)"
    definition: "Praktyka zarządzania infrastrukturą IT za pomocą plików konfiguracyjnych zamiast ręcznej konfiguracji. Narzędzia takie jak Terraform czy CloudFormation umożliwiają wersjonowanie i automatyzację infrastruktury."
  - term: "TCO (Total Cost of Ownership)"
    definition: "Całkowity koszt posiadania infrastruktury IT, obejmujący nie tylko opłaty za serwery, ale także koszty administracji, energii, chłodzenia, licencji i przestojów."
  - term: "Multi-Cloud"
    definition: "Strategia wykorzystania usług od wielu dostawców chmurowych jednocześnie w celu uniknięcia vendor lock-in i optymalizacji kosztów."
sources:
  - url: "https://aws.amazon.com/cloud-migration/"
    title: "AWS Cloud Migration"
  - url: "https://azure.microsoft.com/en-us/solutions/migration/"
    title: "Azure Migration Solutions"
  - url: "https://cloud.google.com/solutions/migration-center"
    title: "Google Cloud Migration Center"
  - url: "https://www.gartner.com/en/information-technology/glossary/cloud-migration"
    title: "Gartner — Cloud Migration Definition"
---

## Czym jest migracja do chmury i dlaczego startupy powinny ją rozważyć

Migracja do chmury to proces przenoszenia aplikacji, danych i infrastruktury IT z tradycyjnych serwerów fizycznych (on-premise) do środowiska chmurowego oferowanego przez dostawców takich jak Amazon Web Services (AWS), Microsoft Azure czy Google Cloud Platform (GCP). Dla startupów ten krok oznacza fundamentalną zmianę w sposobie zarządzania technologią — zamiast inwestować w drogie serwery i zatrudniać administratorów, płacisz tylko za zasoby, których faktycznie używasz.

W tradycyjnym modelu startup musi z góry oszacować zapotrzebowanie na moc obliczeniową, kupić lub wynająć serwery, skonfigurować sieć i zadbać o bezpieczeństwo fizyczne. To generuje wysokie koszty początkowe i ryzyko — jeśli produkt nie odniesie sukcesu, inwestycja w infrastrukturę jest stracona. Chmura eliminuje ten problem, oferując model pay-as-you-go, w którym skalujesz zasoby w górę lub w dół w zależności od aktualnych potrzeb.

Według danych branżowych ponad 90% organizacji korzysta z usług chmurowych w jakiejś formie, a startupy są jednymi z najszybciej adoptujących tę technologię. Powód jest prosty — chmura daje przewagę konkurencyjną poprzez szybkość wdrażania nowych funkcji, globalny zasięg i dostęp do zaawansowanych usług (machine learning, analityka, IoT) bez konieczności budowania ich od zera.

## Strategie migracji do chmury — 6R Framework

Nie każda migracja wygląda tak samo. Gartner i AWS popularyzują framework „6R", który opisuje sześć głównych strategii migracji. Wybór odpowiedniej strategii zależy od charakteru aplikacji, budżetu i celów biznesowych.

### Rehost (Lift and Shift)

Najprostsza strategia — przenosisz aplikację do chmury bez zmian w kodzie czy architekturze. Serwer wirtualny zastępuje serwer fizyczny. To najszybsza metoda, idealna gdy zależy Ci na czasie, ale nie wykorzystuje w pełni możliwości chmury. Dla startupów z legacy aplikacjami to dobry pierwszy krok.

### Replatform (Lift, Tinker and Shift)

Przenosisz aplikację z drobnymi optymalizacjami — na przykład zamiana lokalnej bazy danych na zarządzaną usługę RDS, albo przeniesienie plików statycznych do S3. Niewielki dodatkowy wysiłek, ale znaczące korzyści w postaci mniejszej administracji i lepszej wydajności.

### Refactor / Re-architect

Gruntowna przebudowa aplikacji z wykorzystaniem natywnych usług chmurowych — kontenery, serverless, mikroserwisy. Najdroższa i najdłuższa strategia, ale daje największe korzyści długoterminowe. Dla startupów budujących nowe produkty to często najlepsza opcja od samego początku.

### Repurchase

Zamiana istniejącego rozwiązania na usługę SaaS. Na przykład migracja z self-hosted CRM na Salesforce, albo z własnego serwera e-mail na Google Workspace. Dla startupów to często najrozsądniejszy wybór — po co utrzymywać własne narzędzia, skoro gotowe rozwiązania są tańsze i lepsze?

### Retire

Wyłączenie aplikacji, które nie są już potrzebne. Audyt przed migracją często ujawnia systemy, z których nikt nie korzysta. Wyłączenie ich zmniejsza zakres migracji i obniża koszty.

### Retain

Świadoma decyzja o pozostawieniu niektórych systemów on-premise — na przykład ze względu na regulacje prawne, wymagania dotyczące latencji lub koszty migracji przewyższające korzyści. To nie porażka, to pragmatyzm.

## Planowanie migracji krok po kroku

Skuteczna migracja wymaga systematycznego podejścia. Poniżej przedstawiamy sprawdzony proces, który minimalizuje ryzyko i maksymalizuje szanse na sukces.

### Audyt istniejącej infrastruktury

Zanim cokolwiek przeniesiesz, musisz dokładnie wiedzieć, co masz. Zinwentaryzuj wszystkie serwery, aplikacje, bazy danych, zależności między systemami i przepływy danych. Narzędzia takie jak AWS Application Discovery Service czy Azure Migrate pomagają w automatyzacji tego procesu.

Dla każdej aplikacji określ: kto jest właścicielem, ile zasobów zużywa, jakie ma zależności, jakie są wymagania dotyczące dostępności i wydajności. Ten etap jest kluczowy — pominięcie go prowadzi do niespodzianek podczas migracji.

### Wybór dostawcy chmurowego

Trzej główni dostawcy — AWS, Azure i GCP — oferują porównywalne usługi bazowe, ale różnią się w szczegółach. AWS ma najszerszy ekosystem i największą społeczność, Azure najlepiej integruje się z narzędziami Microsoft, a GCP wyróżnia się w obszarze danych i machine learning.

Dla startupów kluczowe kryteria wyboru to: dostępność programów kredytowych (AWS Activate, Azure for Startups, Google for Startups), jakość dokumentacji, dostępność specjalistów na rynku pracy i kompatybilność z istniejącym stosem technologicznym.

### Projektowanie architektury docelowej

Na podstawie audytu i wybranej strategii migracji zaprojektuj architekturę docelową. Uwzględnij: strukturę kont i organizacji (AWS Organizations, Azure Management Groups), sieć (VPC, subnety, security groups), zarządzanie tożsamością (IAM), strategię backupów i disaster recovery, monitoring i alerting.

Dla startupów rekomendujemy podejście Infrastructure as Code (IaC) od samego początku. Narzędzia takie jak Terraform czy AWS CloudFormation pozwalają wersjonować infrastrukturę i odtwarzać ją w minuty zamiast dni.

### Migracja pilotażowa

Zacznij od migracji jednej, mniej krytycznej aplikacji. To pozwala przetestować proces, zidentyfikować problemy i zbudować kompetencje zespołu bez ryzyka dla kluczowych systemów. Dokumentuj każdy krok — te notatki będą bezcenne przy migracji kolejnych aplikacji.

### Migracja produkcyjna

Po udanym pilocie przenieś pozostałe aplikacje zgodnie z ustalonym harmonogramem. Kluczowe zasady: migruj w oknie serwisowym, miej plan rollbacku, monitoruj wydajność po migracji, informuj użytkowników o planowanych przerwach.

### Optymalizacja po migracji

Migracja to nie koniec, to początek. Po przeniesieniu aplikacji do chmury regularnie analizuj koszty (AWS Cost Explorer, Azure Cost Management), optymalizuj rozmiary instancji (right-sizing), wdrażaj Reserved Instances lub Savings Plans dla przewidywalnych obciążeń i automatyzuj skalowanie.

## Koszty migracji do chmury — na co się przygotować

Koszty migracji to jeden z najczęstszych powodów wahania przed przejściem do chmury. Warto jednak patrzeć na nie w kontekście TCO (Total Cost of Ownership), a nie tylko bezpośrednich wydatków.

### Koszty bezpośrednie

Bezpośrednie koszty migracji obejmują: czas pracy zespołu (lub koszt zewnętrznego konsultanta), ewentualne licencje na narzędzia migracyjne, koszty równoległego działania starej i nowej infrastruktury w okresie przejściowym oraz szkolenia zespołu.

Dla typowego startupu z 3-5 mikroserwisami i jedną bazą danych koszt migracji lift-and-shift to około 5 000-15 000 PLN. Pełna modernizacja cloud-native może kosztować 20 000-80 000 PLN, ale długoterminowe oszczędności operacyjne zwykle zwracają tę inwestycję w ciągu 6-12 miesięcy.

### Koszty operacyjne w chmurze

Po migracji główne koszty to: compute (EC2, Azure VMs, GCE), storage (S3, Azure Blob, GCS), bazy danych (RDS, Azure SQL, Cloud SQL), transfer danych (szczególnie wychodzący — to częsta pułapka kosztowa) i usługi dodatkowe (monitoring, CDN, DNS).

Startupy mogą znacząco obniżyć koszty korzystając z: instancji spot/preemptible (do 90% taniej), programów kredytowych dla startupów, darmowych tier-ów (AWS Free Tier, Azure Free Account) i automatycznego skalowania w dół poza godzinami szczytu.

### Ukryte koszty

Nie zapominaj o kosztach, które łatwo przeoczyć: szkolenia zespołu, czas na naukę nowych narzędzi, koszty compliance i audytów bezpieczeństwa, koszty transferu danych między regionami i potencjalne kary za przekroczenie limitów.

## Bezpieczeństwo w chmurze — najlepsze praktyki

Bezpieczeństwo to obszar, w którym chmura oferuje paradoksalnie lepszą ochronę niż większość rozwiązań on-premise — pod warunkiem prawidłowej konfiguracji. Dostawcy chmurowi inwestują miliardy w bezpieczeństwo fizyczne i logiczne swoich data center.

### Model współdzielonej odpowiedzialności

Kluczowa koncepcja to Shared Responsibility Model. Dostawca chmurowy odpowiada za bezpieczeństwo infrastruktury (fizyczne serwery, sieć, hypervisor), a Ty odpowiadasz za bezpieczeństwo tego, co na niej uruchamiasz (konfiguracja, dane, uprawnienia, aplikacje).

### Zarządzanie tożsamością i dostępem (IAM)

Wdrożenie zasady najmniejszych uprawnień (Principle of Least Privilege) to fundament bezpieczeństwa w chmurze. Każdy użytkownik i serwis powinien mieć tylko te uprawnienia, które są niezbędne do wykonania jego zadań. Używaj ról IAM zamiast kluczy dostępowych, włącz MFA dla wszystkich kont i regularnie audytuj uprawnienia.

### Szyfrowanie danych

Szyfruj dane zarówno w spoczynku (at rest), jak i w tranzycie (in transit). Dostawcy chmurowi oferują zarządzane usługi szyfrowania (AWS KMS, Azure Key Vault, Google Cloud KMS), które upraszczają ten proces. Dla danych wrażliwych rozważ szyfrowanie po stronie klienta (client-side encryption).

### Monitoring i reagowanie na incydenty

Wdróż centralny system logowania i monitoringu od pierwszego dnia. AWS CloudTrail, Azure Monitor i Google Cloud Logging rejestrują wszystkie operacje na zasobach chmurowych. Skonfiguruj alerty na podejrzane aktywności — nieautoryzowane logowania, zmiany w security groups, dostęp do wrażliwych danych.

## Najczęstsze błędy przy migracji do chmury

Doświadczenie pokazuje, że startupy popełniają podobne błędy podczas migracji. Znajomość tych pułapek pozwala ich uniknąć.

### Brak planu migracji

Największy błąd to podejście „po prostu przenieśmy wszystko do chmury". Bez jasnego planu, audytu i zdefiniowanych celów migracja zamienia się w chaos. Każda migracja powinna mieć udokumentowaną strategię, harmonogram i kryteria sukcesu.

### Ignorowanie kosztów transferu danych

Transfer danych wychodzących z chmury (egress) jest płatny i może generować zaskakująco wysokie rachunki. Planuj architekturę tak, aby minimalizować transfer między regionami i do internetu. Używaj CDN dla treści statycznych i cache'uj dane tam, gdzie to możliwe.

### Przenoszenie złych praktyk do chmury

Migracja lift-and-shift przenosi nie tylko aplikacje, ale też złe nawyki — ręczna konfiguracja, brak automatyzacji, monolityczna architektura. Chmura daje szansę na poprawę tych praktyk, ale wymaga to świadomego wysiłku.

### Brak strategii wyjścia

Vendor lock-in to realne ryzyko. Projektuj architekturę z myślą o przenośności — używaj kontenerów, standardowych API i narzędzi open-source tam, gdzie to możliwe. Nie oznacza to unikania usług zarządzanych, ale świadomego wyboru, gdzie akceptujesz zależność od dostawcy.

## Narzędzia wspierające migrację

Ekosystem narzędzi do migracji jest bogaty. Oto najważniejsze kategorie i przykłady.

### Narzędzia do odkrywania i planowania

AWS Application Discovery Service, Azure Migrate i Google Cloud Migrate automatyzują inwentaryzację istniejącej infrastruktury i pomagają w planowaniu migracji. Dla startupów z prostą infrastrukturą często wystarczy ręczny audyt w arkuszu kalkulacyjnym.

### Narzędzia do migracji danych

AWS Database Migration Service (DMS), Azure Database Migration Service i Google Database Migration Service obsługują migrację baz danych z minimalnym przestojem. Dla plików i obiektów używaj AWS DataSync, Azure Data Box lub gsutil.

### Infrastructure as Code

Terraform, AWS CloudFormation, Azure Bicep i Google Cloud Deployment Manager pozwalają definiować infrastrukturę jako kod. Dla startupów Terraform jest najczęstszym wyborem ze względu na wsparcie wielu dostawców i dużą społeczność.

Przy planowaniu migracji warto rozważyć współpracę z doświadczonym partnerem. [Zespół Devopsity specjalizuje się w migracjach do chmury](https://devopsity.com/pl/services/cloud-migration) i może pomóc w uniknięciu typowych błędów, przyspieszeniu procesu i optymalizacji kosztów od samego początku.

### Monitoring i observability

Datadog, New Relic, Grafana Cloud i natywne narzędzia dostawców (CloudWatch, Azure Monitor, Cloud Monitoring) zapewniają wgląd w wydajność i zdrowie aplikacji po migracji. Wdróż monitoring przed migracją, aby mieć punkt odniesienia (baseline) do porównań.

## Automatyzacja i DevOps w kontekście migracji

Migracja do chmury to idealny moment na wdrożenie praktyk DevOps i automatyzacji. Ręczne zarządzanie infrastrukturą, które mogło działać przy kilku serwerach on-premise, nie skaluje się w środowisku chmurowym z dziesiątkami usług i dynamicznie zmieniającymi się zasobami.

### CI/CD Pipeline

Continuous Integration i Continuous Deployment to fundament nowoczesnego wytwarzania oprogramowania. W chmurze pipeline CI/CD może automatycznie budować, testować i wdrażać aplikacje przy każdym commicie. Narzędzia takie jak GitHub Actions, GitLab CI, Jenkins czy AWS CodePipeline integrują się natywnie z usługami chmurowymi.

Dla startupów rekomendujemy GitHub Actions ze względu na prostotę konfiguracji, darmowy tier dla publicznych repozytoriów i natywną integrację z ekosystemem GitHub. Pipeline powinien obejmować: budowanie aplikacji, uruchamianie testów jednostkowych i integracyjnych, statyczną analizę kodu, budowanie obrazów kontenerów i wdrażanie na środowisko staging, a po zatwierdzeniu — na produkcję.

### Konteneryzacja z Docker i Kubernetes

Kontenery rozwiązują klasyczny problem „u mnie działa" — aplikacja uruchamia się identycznie na laptopie developera, na serwerze CI i w produkcji. Docker to standard konteneryzacji, a Kubernetes (K8s) to najpopularniejszy orkiestrator kontenerów.

Dla startupów na wczesnym etapie Kubernetes może być przesadą. Alternatywy takie jak AWS ECS (Elastic Container Service), Azure Container Apps czy Google Cloud Run oferują prostsze zarządzanie kontenerami bez złożoności K8s. Kubernetes warto rozważyć, gdy zespół rośnie, a liczba mikroserwisów przekracza 10-15.

### Monitoring i Observability

Trzy filary observability to: logi (co się wydarzyło), metryki (jak system się zachowuje) i traces (jak żądania przepływają przez system). W chmurze każdy z tych filarów ma dedykowane narzędzia.

Centralny system logowania (ELK Stack, Loki, CloudWatch Logs) zbiera logi ze wszystkich serwisów w jednym miejscu. Metryki (Prometheus, CloudWatch Metrics, Datadog) pokazują zdrowie systemu w czasie rzeczywistym. Distributed tracing (Jaeger, X-Ray, Zipkin) pozwala śledzić żądania przez łańcuch mikroserwisów i identyfikować wąskie gardła.

Wdrożenie observability przed migracją daje punkt odniesienia — możesz porównać wydajność aplikacji przed i po migracji i szybko zidentyfikować regresje.

## Migracja a compliance i regulacje

Dla startupów działających w regulowanych branżach (fintech, healthtech, edtech) migracja do chmury wymaga dodatkowej uwagi na kwestie compliance.

### RODO / GDPR

Dane osobowe obywateli UE muszą być przetwarzane zgodnie z RODO. Dostawcy chmurowi oferują regiony w UE (Frankfurt, Irlandia, Paryż), co ułatwia spełnienie wymogów dotyczących lokalizacji danych. Upewnij się, że Twoja umowa z dostawcą (DPA — Data Processing Agreement) jest zgodna z RODO.

### Certyfikacje branżowe

AWS, Azure i GCP posiadają certyfikacje ISO 27001, SOC 2, PCI DSS i wiele innych. Korzystanie z certyfikowanej infrastruktury ułatwia uzyskanie własnych certyfikacji, ale nie zwalnia z odpowiedzialności za bezpieczeństwo aplikacji i danych.

### Lokalizacja danych i suwerenność cyfrowa

Coraz więcej regulacji wymaga, aby dane były przechowywane w określonym regionie geograficznym. Dostawcy chmurowi odpowiadają na te wymagania, oferując regiony w wielu krajach. W kontekście polskich startupów kluczowe są regiony w UE — Frankfurt (eu-central-1 w AWS), Irlandia (eu-west-1) i Paryż (eu-west-3). Azure oferuje region Poland Central w Warszawie, co jest szczególnie istotne dla firm przetwarzających dane wrażliwe polskich obywateli.

Przed migracją przeprowadź analizę przepływu danych (data flow mapping) — zidentyfikuj, jakie dane przetwarzasz, gdzie są przechowywane, kto ma do nich dostęp i jakie regulacje mają zastosowanie. Ta analiza jest nie tylko wymogiem prawnym, ale też dobrą praktyką inżynierską, która pomaga w projektowaniu bezpiecznej architektury.

## Przyszłość migracji — trendy na 2024 i dalej

Rynek chmurowy ewoluuje dynamicznie. Kilka trendów, które warto obserwować: rosnąca popularność serverless i edge computing, integracja AI/ML jako natywnych usług chmurowych, rozwój platform FinOps do optymalizacji kosztów, oraz coraz większy nacisk na sustainability i ślad węglowy infrastruktury IT. Startupy, które zaczną swoją przygodę z chmurą teraz, będą w najlepszej pozycji, aby wykorzystać te trendy w przyszłości.

## Podsumowanie — kiedy i jak zacząć migrację

Migracja do chmury to nie pytanie „czy", ale „kiedy" i „jak". Dla startupów optymalny moment to jak najwcześniej — im mniej legacy infrastruktury, tym prostsza i tańsza migracja.

Kluczowe rekomendacje na start: zacznij od audytu tego, co masz; wybierz strategię migracji dopasowaną do Twoich potrzeb i budżetu; zacznij od pilota na mniej krytycznej aplikacji; wdrażaj Infrastructure as Code od pierwszego dnia; monitoruj koszty i optymalizuj regularnie; nie bój się prosić o pomoc — doświadczony partner może zaoszczędzić tygodnie pracy i tysiące złotych.

Chmura to nie tylko technologia — to zmiana sposobu myślenia o infrastrukturze IT. Dla startupów to szansa na konkurowanie z dużymi graczami na równych zasadach, bez milionowych inwestycji w hardware. Elastyczność, skalowalność i dostęp do najnowszych technologii sprawiają, że chmura jest naturalnym środowiskiem dla innowacyjnych firm. Wykorzystaj ją mądrze, planuj strategicznie i nie bój się eksperymentować — to właśnie w chmurze eksperymenty są najtańsze.

## Definicje kluczowych pojęć

<dfn>Lift and Shift</dfn> — strategia migracji polegająca na przeniesieniu aplikacji do chmury bez zmian w architekturze. Najszybsza metoda, ale nie wykorzystuje w pełni możliwości chmury.

<dfn>Cloud-Native</dfn> — podejście do budowania aplikacji zaprojektowanych specjalnie dla środowiska chmurowego, wykorzystujących kontenery, mikroserwisy i orkiestrację.

<dfn>IaC (Infrastructure as Code)</dfn> — praktyka zarządzania infrastrukturą IT za pomocą plików konfiguracyjnych zamiast ręcznej konfiguracji. Narzędzia takie jak Terraform czy CloudFormation umożliwiają wersjonowanie i automatyzację infrastruktury.

<dfn>TCO (Total Cost of Ownership)</dfn> — całkowity koszt posiadania infrastruktury IT, obejmujący nie tylko opłaty za serwery, ale także koszty administracji, energii, chłodzenia, licencji i przestojów.

<dfn>Multi-Cloud</dfn> — strategia wykorzystania usług od wielu dostawców chmurowych jednocześnie w celu uniknięcia vendor lock-in i optymalizacji kosztów.

## Źródła

1. [AWS Cloud Migration](https://aws.amazon.com/cloud-migration/) — oficjalna dokumentacja AWS dotycząca migracji do chmury.
2. [Azure Migration Solutions](https://azure.microsoft.com/en-us/solutions/migration/) — przewodnik Microsoft po migracji do Azure.
3. [Google Cloud Migration Center](https://cloud.google.com/solutions/migration-center) — narzędzia i dokumentacja Google Cloud do planowania migracji.
4. [Gartner — Cloud Migration Definition](https://www.gartner.com/en/information-technology/glossary/cloud-migration) — definicja i analiza migracji chmurowej według Gartner.

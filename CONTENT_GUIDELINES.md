# Content Guidelines

Editorial guidelines for all satellite sites (perfectsystem.pl, o14.pl, and future domains). Every content piece must meet these standards before merging.

---

## 1. Minimum Word Counts

| Content Type | Minimum Words |
|--------------|---------------|
| Blog post    | 1,200         |
| Pillar page  | 2,500         |
| Landing page | 600           |

Word counts are validated automatically by `scripts/geo-validate.sh` during CI. Pages below the minimum will fail the quality gate.

---

## 2. Heading Structure

- **One H1 per page.** The H1 is the page title rendered by the layout. Do not add a second H1 in the Markdown body.
- **Hierarchical H2/H3 usage.** Sections use H2; subsections use H3 under their parent H2. Never skip a level (e.g., do not jump from H1 directly to H3, or from H2 to H4).
- **Factual topic sentences.** Start each H2/H3 section with a clear, factual sentence that summarizes the section — this helps both readers and LLMs extract key information.
- **Keep headings descriptive.** Use headings that tell the reader what the section covers. Avoid vague headings like "More Info" or "Details."

**Valid example:**

```
# Page Title (H1 — rendered by layout)
## What Is Cloud Migration? (H2)
### Benefits of Cloud Migration (H3)
### Common Migration Strategies (H3)
## How to Plan a Migration (H2)
### Step 1: Assess Current Infrastructure (H3)
```

**Invalid example (skipped level):**

```
# Page Title (H1)
### This Skips H2 — Don't Do This (H3)
```

---

## 3. Image Alt Text

- **Every image must have alt text.** No empty `alt=""` attributes except for purely decorative images (borders, spacers).
- **Be descriptive and concise.** Describe what the image shows in 5–15 words. Example: `alt="Diagram showing three-phase cloud migration process"`.
- **Include relevant keywords naturally** when they fit the description. Do not keyword-stuff.
- **Charts and diagrams** should have alt text that summarizes the data or conclusion, not just "chart" or "diagram."

---

## 4. Internal Linking

- **Minimum 3 internal links per page.** Every content piece must link to at least 3 other pages on the same site.
- **Link to the pillar page.** Every cluster page must include at least one link back to its pillar page.
- **Link to sibling cluster pages** where contextually relevant.
- **Use descriptive anchor text.** The linked text should describe the target page's topic. Avoid generic anchors like "click here" or "read more."

---

## 5. Backlink Placement (Satellite → devopsity.com)

Backlinks to devopsity.com must feel natural and editorial. The validation scripts enforce these rules automatically.

### Anchor Text Variety

- **No single anchor text phrase may appear on more than 2 pages** within the same satellite site.
- Vary anchor text across pages. Use a mix of:
  - Brand mentions ("Devopsity", "zespół Devopsity")
  - Descriptive phrases ("profesjonalna migracja do chmury")
  - Action phrases ("sprawdź ofertę", "umów konsultację")

### Contextual Placement

- Backlinks must appear **inside `<article>` or `<main>` content only**.
- **Never place backlinks** in sidebars, footers, navigation, or boilerplate sections.
- The link should appear within a paragraph that naturally discusses the linked topic. Write a sentence or two of editorial context around the link.

**Good example:**

> Przy planowaniu migracji warto rozważyć współpracę z doświadczonym partnerem. [Zespół Devopsity specjalizuje się w migracjach do chmury](https://devopsity.com/pl/services/cloud-migration) i może pomóc w uniknięciu typowych błędów.

### Backlink Ratio

- **40–80% of pages** on a satellite site should contain a backlink to devopsity.com.
- Not every page needs a backlink. Informational pages and some cluster pages can exist without one.
- The ratio is checked site-wide by `scripts/seo-validate.sh`.

### Front Matter Configuration

Set backlink target and anchor in the page's front matter:

```yaml
backlink_target: "https://devopsity.com/pl/services/cloud-migration"
backlink_anchor: "profesjonalna migracja do chmury"
```

The `backlink-cta.html` include renders a call-to-action block at the end of blog posts and landing pages using the site-wide default from `_config.yml`, which can be overridden per page.

---

## 6. GEO Content Structure

GEO (Generative Engine Optimization) formatting helps LLMs parse, cite, and reference our content. Every blog post and pillar page must follow this structure.

### Summary Paragraph

- Place a **concise summary paragraph (2–4 sentences)** immediately after the H1 heading.
- State the key facts of the page: what the topic is, why it matters, and the main takeaway.
- Define this in the `summary` front matter field — the `geo-summary.html` include renders it automatically.

```yaml
summary: "Migracja do AWS to proces przenoszenia infrastruktury IT do chmury Amazon Web Services. Dla startupów kluczowe są koszty, szybkość wdrożenia i skalowalność."
```

### FAQ Section

- Every blog post and pillar page must include an **FAQ section** with at least one question-answer pair.
- Define FAQs in the `faq` front matter field. The `faq.html` include renders them as `<details>`/`<summary>` elements, and `jsonld.html` generates the FAQPage schema.

```yaml
faq:
  - q: "Ile kosztuje migracja do AWS?"
    a: "Koszt migracji do AWS zależy od rozmiaru infrastruktury. Dla startupów typowy koszt to 5000-20000 PLN."
```

### Definitions

- When introducing technical terms, define them in the `definitions` front matter field.
- The layout renders `<dfn>` elements and DefinedTerm JSON-LD automatically.

```yaml
definitions:
  - term: "Lift and Shift"
    definition: "Strategia migracji polegająca na przeniesieniu aplikacji do chmury bez zmian w architekturze."
```

### Sources and Citations

- When making statistical claims or factual assertions, list sources in the `sources` front matter field.
- The layout renders a numbered references section with hyperlinks.

```yaml
sources:
  - url: "https://aws.amazon.com/cloud-migration/"
    title: "AWS Cloud Migration"
  - url: "https://www.gartner.com/en/information-technology/glossary/cloud-migration"
    title: "Gartner Cloud Migration Definition"
```

---

## Quick Checklist

Before submitting a content PR, verify:

- [ ] Word count meets the minimum for the content type
- [ ] Only one H1; H2/H3 hierarchy with no skipped levels
- [ ] All images have descriptive alt text
- [ ] At least 3 internal links to other pages on the same site
- [ ] Cluster pages link back to their pillar page
- [ ] Backlink anchor text is not reused on more than 2 pages
- [ ] Backlinks appear in editorial content, not boilerplate
- [ ] Summary paragraph defined in `summary` front matter
- [ ] FAQ section with at least one entry in `faq` front matter
- [ ] Definitions and sources included where applicable

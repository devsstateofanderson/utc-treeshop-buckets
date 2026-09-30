# Contributing to OpenLoadout

OpenLoadout gets better when the people who run the saws, order the parts and plant the trees correct it. This page explains how to propose **adding**, **changing** or **removing** an item or a rule, what evidence you need, and how the change reaches a Baseline release.

## The short version

1. Open a pull request against the **`next`** branch. If you can't use git, open an issue and include the same information.
2. Say what you want to add, change or remove, and give the row ID if the row already exists.
3. Give a **source URL and the date you saw it** for every price and every spec.
4. Propose a **Confidence level**.
5. Write a one-line reason.

## 1. What each kind of change needs

| Change | Required | Also required when… |
|---|---|---|
| **Add a row** | The list it belongs to, based on the one-question tests (STANDARD.md §2.1); name; stock unit; spec (for a chain: pitch · gauge · drive links, all three); price with its source URL and date; proposed Confidence | It is a wear part: name the unit it wears on, its interval, and the evidence for that interval. It is a plant: zone fit, invasive status (FISC list) and disease-host status, each with a source |
| **Change a row** | Row ID, the field, old value, new value, source URL and date | The change moves a row to a different list: show which one-question test it fails in its current list |
| **Remove a row** | Row ID and the reason, with a source (discontinued, superseded, unsafe, invasive, unlawful, duplicate of another row ID) | Rows are **retired, never deleted or renumbered**. Name the replacement row if there is one |
| **Change a rule or a Baseline default** (the saw line, the default nursery, a removed species, a boundary rule, a compliance gate) | Everything above, plus why the current rule causes a wrong price, a wrong fit or a safety or legal problem | Needs the project owner's yes as well as maintainer review (§5) |
| **Price refresh** | Row ID, new price, vendor, source URL, date seen, price basis (each, pack, pail, kit…) and pack quantity | None. Price refreshes are routine |

A row with no price can still be proposed. It lands with Confidence `missing` and does not count as a priced row.

## 2. Required evidence

- **Every price and every spec needs a source URL and the date you read it.** Record prices in the local currency (USD for the Baseline) exactly as shown, and say whether the price is a sale price or the regular price.
- **Link the page where the fact appears.** A search-results page or a homepage is not evidence. For a manual, cite the document number and section (for example, "US manual 0458-599-8621-C §29.8").
- **Use the right regional edition.** A US standard cites US manuals, which can differ from EU editions.
- **Label estimates honestly.** Use one of the tags below. A figure you could not check is `[unverified]`, and nobody prices from it.

| Tag | Meaning |
|---|---|
| `[V date]` | Verified: read on the cited page on that date |
| `[M]` | Manufacturer instruction: from the maker's manual or parts list, section cited |
| `[owner baseline]` | A company owner's stated starting figure, to be replaced by logged data |
| `[rule of thumb]` | An industry planning figure with no manufacturer source |
| `[illustrative]` | A placeholder used to show arithmetic |
| `[unverified]` | Could not be checked |

- **Keep private data out of every contribution.** Never include serial numbers, VINs, EINs, policy numbers, tax IDs, wages, customer names or addresses, or any personal data, and never put them in screenshots. A contribution that contains any of these is closed and its history purged.
- **Quote very little and link instead.** Cite a manual's section rather than pasting its text, and don't copy a supplier's product description.
- **Disclose conflicts of interest.** If you work for or sell for a vendor you cite, say so in the pull request. Vendor contributions are welcome and are held to the same evidence rules.
- **No marketing claims.** A row states what the item is, what it costs and where the evidence is.

## 3. Confidence levels

Every priced row and every wear line carries one Confidence level.

| Level | Meaning | Who may set it |
|---|---|---|
| `missing` | No usable price or spec yet | Anyone |
| `estimated` | A reasoned figure without direct evidence, such as a rule of thumb or a price from a similar item | Anyone; say how it was estimated |
| `verified` | Read on the cited source on a stated date. Requires **both** the URL **and** the checked date. A review is due one year later | Proposed by anyone; granted by a maintainer after checking the source |
| `ownerConfirmed` | Confirmed by an adopting company's owner for that company's own list | Reserved for the adopting company. The public Baseline does not use it |

A hand-edited file cannot make a row verified. An unresolved row never blocks a price in Buckets, but it is flagged and counted until someone fixes it.

## 4. How disputes are settled

When two sources disagree, the higher one in this order wins. The pull request records both sources and which one won.

1. **Law and regulation.** Statutes, administrative codes, federal regulations, local ordinances, and the licence conditions they impose. **Law beats practice:** a common habit never overrides a legal requirement.
2. **Safety standards and the manufacturer's safety instructions.** ANSI Z133 for arboricultural operations, and the manufacturer's approved bar-and-chain list. **No unapproved conversion is ever accepted,** however many people run it. These are life-safety tools.
3. **Manufacturer documentation.** Instruction manuals, parts lists and the manufacturer's own product pages. **Manufacturer documentation beats retailer listings:** when a retailer's spec line contradicts the manufacturer's part number or manual, the manufacturer wins.
4. **Public agencies and universities** for plants and regulation: for example, UF/IFAS fact sheets, the FISC invasive plant list and FDACS. For plant decisions these outrank nursery catalogs.
5. **Major suppliers' listings** (for example Bailey's, Sherrilltree, TreeStuff and WesSpur, or an authorized dealer) for prices and availability.
6. **Other retailers and marketplaces.**
7. **Rules of thumb and experience.** Welcome, but labelled `[rule of thumb]` and replaced by logged data when it exists.

Tie-breaks:

- **Newer beats older** at the same level, when the document is dated (a 2026 edition supersedes a 2017 one).
- **The regional edition beats the foreign one** (the US manual for a US standard).
- **A company's logged data beats a rule of thumb** for its own intervals and par levels, but logged data does not change the public Baseline default without evidence from more than one company.
- **Prices are observations, not arguments.** Two vendors can both be right on the date each was seen. The Baseline records the one it prices from, with its date. The cheapest price does not win automatically.

If a dispute still can't be settled, the row is marked `[unverified]` with both sources noted, and it stays out of any worked price until the question is resolved.

## 5. Review by the maintainers

The maintainers are UTC, which maintains OpenLoadout and Buckets. They review every pull request for:

- **Evidence:** the URL loads, the date is given, and the value matches the page. A maintainer re-reads every source before granting `verified`.
- **Fit to the schema:** the right list by the one-question tests, one record per thing, a permanent ID, the stock unit from the controlled vocabulary, and a chain given as three numbers.
- **Safety and law:** nothing outside a manufacturer's approved list, and nothing that conflicts with a cited law or gate.
- **Privacy:** no private data anywhere in the change or its history.
- **Scope:** the change belongs in a master standard rather than in one company's own list. Brand preferences, a single company's vendors and local pricing go in that company's own list.

Outcomes: **accepted** (merged to `next`), **changes requested**, or **declined with a reason**. A change to a Baseline default also needs the project owner's yes, recorded in the pull request.

## 6. How changes land in a release

- **Merged changes wait on `next`** until the next release is cut.
- **Point releases** (Baseline N.1, N.2, …) are cut when a Buckets build ships, or earlier when a maintainer decides enough has changed. Each is tagged in git (for example `baseline-1.2`), carries a published date and a prices-seen date, and gets a CHANGELOG entry that lists every accepted change by row ID.
- **Major Baselines** freeze with the Buckets major release (Baseline 1 ships inside Buckets 1.0).
- **Schema changes** (new columns, renamed fields, new connection rules) follow semantic versioning on their own number. A breaking change waits for a major.
- **Adopting companies are never overwritten.** Buckets is planned to show each company the diff and let its owner accept changes row by row.
- **Row IDs never change.** Retired rows stay in the data, marked retired, so older quotes and company lists still resolve.

## 7. License of contributions

By contributing, you agree that your contribution may be published under the project's license. The recommendation, pending the owner's confirmation, is **CC BY 4.0** for data and documentation and **MIT** for code (see README.md). You also confirm that you have the right to submit it and that it contains no private data.

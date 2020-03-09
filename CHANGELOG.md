Changelog
=========

---

#### 2020-03-09
- Fixed a bug with language switching.

#### 2020-03-06
- Updated to Wolcen v1.0.8.0. [Wolcen v1.0.7.0 to v1.0.8.0 source differences.](https://gitlab.com/erosson/wolcendb/-/commit/7774750ece265015b1360ad62bbaf5efeba987d7)
- You can now load WolcenDB with data from old versions of Wolcen.
  - For example, take a look at [v1.0.4.0's overpowered Bleeding Edge](/skill-variant/player_laceration_variant_11?build_revision=1.0.4.3_ER) or [v1.0.6.0's zero-cooldown Winter's Grasp](/skill/player_frostnova?build_revision=1.0.6.0_ER).
- Most pages don't need to wait for `searchIndex` to finish loading any more.
- A limited, non-interactive version of some pages is now shown before `datamine` has finished loading. This will be most visible if you're on mobile or on a slow network.
- Added language selection. Still beta-quality; expect bugs.

#### 2020-03-04
- Images have been restored to loot/unique/skill lists.
- Normal loot now has a "tier" filter, set to tier 16 by default. (You can still select "all tiers" if you like long lists.)
- Wolcen version is now shown on the home page.
- Created a subreddit
- Slightly redesigned some homepage links

#### 2020-03-03
- Images removed from loot/unique/skill lists. They're still visible when viewing only a single item/unique/skill.
  - Site bandwidth has been too high; oops. This is a quick fix. I'd like to bring these images back once I've had time to explore other solutions. Sorry!

#### 2020-03-02
- Search results for skill-variants now link to the skill-variant's page, instead of the skill's page.
- [`/affix`](/affix) now displays keywords for collapsed rows.
- [`/affix`](/affix) supports filtering by prefix/suffix.

#### 2020-03-01
- Added ailment base-damage data.

#### 2020-02-28
- Updated to Wolcen v1.0.7.0. [Wolcen v1.0.6.0 to v1.0.7.0 source differences.](https://gitlab.com/erosson/wolcendb/-/commit/8dd1940849aa9db35ab69f689b24c630a1a63031)
- Skill variants now try to display interesting numbers.
  - This isn't very pretty, but it's now the easiest way I know of to see numbers for things like [Bleeding Edge: Despotic Perseverence's damage per ailment, for example](/skill/player_laceration).
  - I'm sure this needs more work. Let me know which skill-variants are still missing numbers you'd like to see!
- Added skill-variant images.
- Added pages for single skill-variants. (`/skill-variant/...`)
- Added leveling effects to each skill.

#### 2020-02-27
- Item affixes are now grouped by prefix/suffix, instead of a single list with all possible affixes.
  - [Thanks to Wujido](https://youtu.be/jcYnamTR4f8) for teaching me that prefix/suffix matter! Previously I assumed they were an old code artifact and made no difference.
- Weapons now show rage per hit.
- Added an [Offline] link to unique items.

#### 2020-02-26
- Updated to Wolcen v1.0.6.0. [Wolcen v1.0.4.0 to v1.0.6.0 source differences.](https://gitlab.com/erosson/wolcendb/-/commit/c7a8fd560914493c6ee8538a53791159040e6f3f)
- Added a loading indicator.
  - Fixed the loading indicator in IE/Edge a few hours later; oops.

#### 2020-02-25
- Redesigned the affix list.
  - Affixes are now grouped by class.
  - You can filter affixes by level, gem, or keyword.
  - Keywords, Sarisel, CraftOnly, and prefix/suffix take up less space.
- Added Seeker and Diplomat city mission rewards.

#### 2020-02-24
- Redesigned the normal loot list.
  - You can filter the loot list by keyword. There's many links to filtered lists at the top - for example, "two-handed axes" or "heavy helmets".
  - Each list entry is larger, and shows the item image with its implicit stats.
  - Weapons, shields, armor, and accessories now have the same URL format. (Old links still work.)
- Redesigned the unique loot list.
  - High-level versions of uniques are now grouped with their low-level counterparts.
  - Changes similar to the normal loot list:
    - You can filter the loot list by keyword. There's many links to filtered lists at the top - for example, "two-handed axes" or "heavy helmets".
    - Each list entry is larger, and shows the item image with its implicit stats.
    - Weapons, shields, armor, and accessories now have the same URL format. (Old links still work.)

#### 2020-02-22
- Added gem icons for each affix. When crafting, socketed gems influence the odds of each chosen affix - these *gem families* indicate which gems go with each affix.
  - There's no data suggesting that socket type matters
  - Beware: I haven't actually done much crafting yet, so this work isn't well-tested. It's based on [ZiggyD's crafting video](https://www.youtube.com/watch?v=0_u8sCgpSBE) (thanks ZiggyD!), [crafting reagent descriptions](/reagent), and [datamined gem families](https://gitlab.com/erosson/wolcendb/-/tree/master/datamine/Game/Umbra/Loot/MagicEffects/Affixes/Craft/GemFamiliesAndCoveredEffectIDs.xml). Please report any bugs!
- Added item-level and gem-family filters to possible item affix lists.
- Added a list of reagents.
- Added armor and shield properties.
- Fixed a bug that hid an affix for several uniques: The Trial, Driftwood Miracle, Gaälnazek, Expurgation, Maelström, Paradox.
- Added weights for craftable affixes.
- Changed the "Craftable affixes" label to "Craft-only affixes", for clarity.

#### 2020-02-21
- Fixed a bug with affixes that reversed their mandatory keywords and optional keywords.
  - Possible affixes per item have not changed.

#### 2020-02-20
- Added a sitewide search bar.
- Extracted files from the latest Wolcen version, v1.0.4.

#### 2020-02-19
- Added `[source]` links throughout the site. These link to excerpts from the Wolcen game files that WolcenDB gets its data from.
  - This is useful if Wolcen and WolcenDB are still missing data you're interested in (ex. many skill variants), or for tool developers.
- This changelog page now says which Wolcen version WolcenDB was built from.
- Added a list of passive skill tree nodes.

#### 2020-02-18
- Added gems.
- Unique armors and accessories are now categorized correctly.
- Fixed a bug that caused missing images for ~~some~~ all armors.

#### 2020-02-17
- This changelog is now visible on the website.
- Nicer item layouts.
- Magic affixes for each item are now grouped by class.
  - Only one mod from each affix-class may spawn on an item.
- Magic affixes for each item are now much more accurate.
- Added images for items and skills.
- Added Google Analytics.

#### 2020-02-16
- Added upgraded unique versions (max/maxmax).
- Added item levels.
- Added this changelog.
- Initial release

Changelog
=========

---

#### 2020-02-25
- Redesigned the affix list.
  - Affixes are now grouped by class.
  - You can filter affixes by level, gem, or keyword.
  - Keywords, Sarisel, CraftOnly, and prefix/suffix take up less space.

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
  - Beware: I haven't actually done much crafting yet, so this work isn't well-tested. It's based on [ZiggyD's crafting video](https://www.youtube.com/watch?v=0_u8sCgpSBE) (thanks ZiggyD!), [crafting reagant descriptions](/reagent), and [datamined gem families](https://gitlab.com/erosson/wolcendb/-/tree/master/datamine/Game/Umbra/Loot/MagicEffects/Affixes/Craft/GemFamiliesAndCoveredEffectIDs.xml). Please report any bugs!
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

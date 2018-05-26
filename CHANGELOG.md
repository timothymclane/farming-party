# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
- Nothing at this time

## [2.6.0] - 2018-05-26
### Changed
- API version for Summerset chapter

## [2.5.0] - 2018-04-07
### Added
- Options to exclude gear and motifs from looted items
- Option for minimum item quality for looted items
### Fixed
- Some verbiage issues

## [2.4.0] - 2018-02-23
### Added
- Key bind for toggling the highscore window

## [2.3.0] - 2018-02-20
### Added
- Tamriel Trade Centre fallback when neither ATT nor MM are enabled

## [2.2.0] - 2018-02-16
### Added
- Ability to prune members no longer in group—useful when you want to clean up the list when tracking is off.
### Fixed
- Various UI and layout bugs
- Issue where tracking status would not persist between reloads

## [2.1.0] - 2018-02-12
### Changed
- Supported API version to 100022

## [2.0.0] - 2018-01-13
### Changed
- `/fpreset` command to `/fp reset`
### Fixed
- Issue where tracking would not turn off even when user ran pause or stop command
- Instances where settings were not shared across modules

## [1.3.0] - 2018-01-01
### Added
- Items button and window to view all items looted by a particular member
- Settings to toggle group or self item tracking
- Ability to toggle all loot tracking via `/fp start|[pause|stop]`

### Changed
- Loot event handler (specifically value aggregation) to improve performance
- LibAddonMenu 2.0 version from r17 to r25

### Fixed
- Serious (usually silent) bug/performance issue which occurred when a member looted an item

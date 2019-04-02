# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
- Nothing at this time

## [2.11.1] - 2019-04-01
### Fixed
- Missing .xml file

## [2.11.0] - 2019-04-01
### Added
- Configuration option for `/fpc` chat output
- Resize support to the loot window
- Timestamp support to the loot window

## [2.10.1] - 2019-02-03
### Fixed
- Errantly removed API version for Murkmire.

## [2.10.0] - 2019-02-03
### Added
- LibPrice integration. You must install this lib manually.
### Changed
- API version for Wrathstone DLC

## [2.9.0] - 2018-08-13
### Added
- Addon terms from ZOS
### Changed
- API version for Wolfhunter DLC

## [2.8.0] - 2018-07-28
### Changed
- Price formatting to use delimiters
- Chat logging to make it more consistent

## [2.7.0] - 2018-07-01
### Changed
- Arkadius' Trade Tools price queries to use the tooltip date range setting instead of the price from the last 30 days

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

[2.11.1]: https://github.com/timothymclane/farming-party/compare/release%2Fv2.11.0...release%2Fv2.11.1
[2.11.0]: https://github.com/timothymclane/farming-party/compare/release%2Fv2.10.1...release%2Fv2.11.0
[2.10.1]: https://github.com/timothymclane/farming-party/compare/release%2Fv2.10.0...release%2Fv2.10.1
[2.10.0]: https://github.com/timothymclane/farming-party/compare/release%2Fv2.9.0...release%2Fv2.10.0
[2.9.0]: https://github.com/timothymclane/farming-party/compare/release%2Fv2.8.0...release%2Fv2.9.0
[2.8.0]: https://github.com/timothymclane/farming-party/compare/release%2Fv2.7.0...release%2Fv2.8.0
[2.7.0]: https://github.com/timothymclane/farming-party/compare/release%2Fv2.6.0...release%2Fv2.7.0
[2.6.0]: https://github.com/timothymclane/farming-party/compare/release%2Fv2.5.0...release%2Fv2.6.0
[2.5.0]: https://github.com/timothymclane/farming-party/compare/release%2Fv2.4.0...release%2Fv2.5.0
[2.4.0]: https://github.com/timothymclane/farming-party/compare/release%2Fv2.3.0...release%2Fv2.4.0
[2.3.0]: https://github.com/timothymclane/farming-party/compare/release%2Fv2.2.0...release%2Fv2.3.0
[2.2.0]: https://github.com/timothymclane/farming-party/compare/release%2Fv2.1.0...release%2Fv2.2.0
[2.1.0]: https://github.com/timothymclane/farming-party/compare/release%2Fv2.0.0...release%2Fv2.1.0
[2.0.0]: https://github.com/timothymclane/farming-party/compare/release%2Fv1.3.0...release%2Fv2.0.0
[1.3.0]: https://github.com/timothymclane/farming-party/compare/release%2Fv1.2.1...release%2Fv1.3.0
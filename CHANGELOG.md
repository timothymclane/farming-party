# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
- Nothing at this time

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
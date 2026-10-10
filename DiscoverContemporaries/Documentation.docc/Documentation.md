# ``DiscoverContemporaries``

Explore history through overlapping lifespans.

## Overview

DiscoverContemporaries is an iOS application designed to help university history students explore historical figures who lived during the same periods.

The application allows users to discover contemporaries, compare the lifespans of historical figures, and explore historical connections across geographical regions and occupations.

Users can search for historical figures, view their profiles, visualise lifespans on an interactive timeline, and save figures for future reference.

### Key Features

- **Historical Figure Search:** Search for historical figures using Wikidata.

@Image(
    source: "home.png",
    alt: "Home screen with historical figure search and discovery"
)

- **Figure Profiles:** View biographical information, lifespans, occupations, and historical movements.

@Image(
    source: "profile.png",
    alt: "Historical figure profile displaying biographical details"
)

- **Discover Contemporaries:** Find historical figures whose lifespans overlap.
- **Lifespan Comparison:** Compare two historical figures.
- **Interactive Timeline:** Visualise lifespans with scrolling and zoom controls.
- **Explore by Category:** Browse historical figures by region or occupation.
- **Bookmarks:** Save historical figures for later reference.
- **Recently Viewed:** Quickly revisit previously explored figures.

## Architecture

DiscoverContemporaries follows the Model-View-ViewModel (MVVM) architecture to separate user interface components, presentation logic, and data management.

### Technologies

- **SwiftUI:** Declarative user interface development.
- **Combine:** Observable view-model state management.
- **SwiftData:** Local persistence and caching of historical figures.
- **Wikidata API:** Retrieval of historical figures and biographical information.
- **Firebase:** Cloud services integration, where configured.

## Data Management

Historical figure information is retrieved from Wikidata and stored locally using SwiftData.

The caching layer allows previously retrieved figures to be reused without unnecessary network requests.

Repositories manage local persistence, while view models coordinate data retrieval and prepare information for SwiftUI views.

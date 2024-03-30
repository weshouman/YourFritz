# YourFritz Project

<p align="center">
  <img src="yourfritz_logo.png" alt="YourFritz-Logo">
</p>

## Introduction

The YourFritz project is designed to introduce dynamic package management for SOHO/consumer Integrated Access Devices (IADs) developed by AVM, a well-known company based in Berlin, Germany. These multifunctional devices enjoy significant popularity across Germany, Austria, and Switzerland, and have a niche user base in Australia.

## Background

- **Core Basis:** AVM's firmware is built on Linux but includes many proprietary components.
- **Open Source Challenges:** Despite AVM's intentions to release open-source files, the source packages have been incomplete post-transition to kernel version 3.10.73, complicating efforts to compile a functioning kernel.

## Project Contents

This repository is a growing collection of tools aimed at enhancing FRITZ!Box devices:
- **Shell Scripts and Files:** Early contributions are primarily smaller shell scripts and supporting files.
- **Unified Solution Goal:** Each script and file is a step toward a comprehensive package management system.

## Participation

- **Current Status:** The project is currently a solo venture.
- **Call for Collaboration:** We warmly invite developers interested in contributing to this project.

## The Modfs Project

A notable derivative of our initiative:
- **Purpose:** Modfs allows for direct modifications to the vendor-supplied firmware on FRITZ!Box devices without extensive toolchains.
- **Features:**
  - **Command Line Interface:** Rooted in proof-of-concept shell scripts for straightforward customization.
  - **"Boot Manager":** Enables switching between systems on separate partitions, minimizing risks associated with firmware modifications.

## Rationale

Why this project matters:
- **User Needs:** Most FRITZ!OS users seek only an OpenVPN server/client and a SSH server for secure access.
- **Modular Packages:** According to feedback from the Freetz project support forum, these features are highly requested and could reduce the need for broader system changes.

## Future Directions

- **Incremental Development:** We are advancing towards our goal step by step, with optimism for testing an integrated version within the year.
- **Invitation to Test:** As our building blocks mature, we look forward to engaging with the community in testing and refining the first comprehensive update.


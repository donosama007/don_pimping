# FiveM ESX Pimping Script

## Overview
This comprehensive pimping management system allows players to recruit, manage, and profit from working girls in the city. The script features an extensive territory system, girl management, reputation mechanics, and various gameplay systems designed to create an engaging and challenging experience.

## Features

### Core Systems

#### Territory System
- **Territory Discovery & Claiming**: Find and claim territories throughout the city
- **Territory Types**: Standard, Premium, and VIP territories with unique attributes
- **Territory Control**: Maintain control of your territories against NPC and player threats
- **Territory Upgrades**: Upgrade territories in multiple categories:
  - Security: Improves defense against raids and attacks
  - Visibility: Attracts more clients and improves earnings
  - Comfort: Reduces happiness decay and improves working conditions
  - Operations: Enhances overall territory performance and reputation gain
- **Territory Raids**: Defend against NPC gangs and other players trying to take your territory
- **Proximity Requirement**: Must be physically close to a territory to manage it or send girls to work

#### Girl Management
- **Girl Attributes**: Each girl has unique attributes affecting their performance
  - Appearance: Affects client attraction and pricing
  - Performance: Affects client satisfaction and repeat business
  - Loyalty: Affects likelihood of staying with you
  - Discretion: Affects risk of police attention
- **Girl Happiness System**: Keep your girls happy or they might leave
  - Multiple factors affect happiness (working conditions, treatment, etc.)
  - Various activities to improve happiness (gifts, time off, etc.)
  - Girls with 0 happiness will leave permanently
- **Girl Following**: Enhanced system for girls to follow you around the city
  - Proper positioning and pathfinding
  - Multiple girls can follow in formation
  - "Send Home" option makes girls walk away and despawn
- **Girl Discipline**: Slap girls to increase fear and potentially loyalty
  - Proper animations and sound effects
  - Visual feedback on attribute changes

#### Reputation System
- **Reputation Levels**: Progress through different pimp levels
- **Reputation Perks**: Unlock and upgrade various perks using reputation points
  - Business perks: Improve earnings and negotiation skills
  - Protection perks: Reduce police interference and improve territory defense
  - Girl Management perks: Improve girl happiness and loyalty
  - Territory perks: Discover new territories and improve control
  - Special perks: Unlock unique abilities like fast travel
- **Reputation Leaderboard**: Compare your standing with other players
  - Shows all players, not just those with the pimp job
  - Proper sorting by reputation score
  - Pagination for many players
  - Visual indicators for player ranking

#### Client Negotiation System
- **Client Types**: Different client types with varying payment levels
- **Negotiation Options**: Choose to accept the offered price or negotiate
  - Multiple negotiation strategies with different risk/reward profiles
  - Success chance based on girl attributes and your perks
- **Client Response**: Clients may accept, reject, or counter your offers
- **Notification System**: Receive alerts when girls find clients

#### Earnings System
- **Girl Earnings**: Each girl generates income based on their attributes and territory
- **Earnings Withdrawal**: Collect earnings from individual girls
  - Enhanced confirmation dialog shows current earnings amount
  - Success/failure notifications after withdrawal

### User Interface
- **Context Menus**: Easy-to-use menus for all interactions
- **Notifications**: Informative notifications for all events
- **Blips**: Map markers for territories and working girls
- **Visual Feedback**: Clear visual indicators for all actions

## Commands
- `/pimp` - Open the main pimp menu
- `/followme` - Make a girl follow you
- `/stopfollow` - Stop a girl from following you
- `/stopallfollow` - Stop all girls from following you

## Installation Instructions
1. Extract the `don_pimping` folder to your server's resources directory
2. Add `ensure don_pimping` to your server.cfg
3. Import the SQL file from the `sql` folder into your database
4. Restart your server

## Dependencies
- ESX Framework
- ox_lib
- oxmysql

## Configuration
The script is highly configurable through the `shared/config.lua` file. Key configuration options include:

- Framework settings (ESX/QB-Core)
- Permission system
- Girl attributes and pricing
- Territory settings
- Reputation system
- Happiness system

## Troubleshooting
- **Girls not spawning**: Ensure you have the correct ped models available
- **Territory blips not showing**: Check your blip configuration in config.lua
- **Earnings not updating**: Verify your database connection is working properly
- **Permission issues**: Check the permission settings in config.lua

## Credits
- Created by Donald Draper
- Enhanced by NinjaTech AI

## Support
For support, please join our Discord server or open an issue on our GitHub repository.
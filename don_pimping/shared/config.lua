-- Pimp Management System - Enhanced Configuration
-- Created by Donald Draper
-- Optimized by NinjaTech AI
-- Enhanced with Discipline System and New Features

Config = {}

-- General Settings
Config.Debug = true -- Enable debug mode to help diagnose issues
Config.CommandName = "pimp"
Config.DefaultCurrency = "$"

-- Framework Settings
Config.Framework = "esx" -- Options: "qb-core", "esx", "custom"

-- Enhanced Permission System
Config.PermissionSystem = {
    enabled = true,
    whitelist = {
        enabled = true,
        allowedJobs = {
            ["pimp"] = true,
            ["criminal"] = true,
            ["gangster"] = true,
            ["gang"] = true,
            ["mafia"] = true
        },
        requiredJobGrades = {
            ["pimp"] = 0,
            ["criminal"] = 2,
            ["gangster"] = 3,
            ["gang"] = 1,
            ["mafia"] = 2
        }
    },
    itemRequirements = {
        enabled = false,
        requiredItems = {
            ["pimp_license"] = false
        }
    },
    accessLevels = {
        MenuAccess = {
            ["pimp"] = 3,
            ["criminal"] = 2,
            ["gangster"] = 2,
            ["gang"] = 2,
            ["mafia"] = 3
        },
        GirlManagement = {
            ["pimp"] = 3,
            ["criminal"] = 2,
            ["gangster"] = 2,
            ["gang"] = 2,
            ["mafia"] = 3
        },
        GirlPurchase = {
            ["pimp"] = 3,
            ["criminal"] = 2,
            ["gangster"] = 2,
            ["gang"] = 2,
            ["mafia"] = 3
        },
        TerritoryControl = {
            ["pimp"] = 3,
            ["criminal"] = 1,
            ["gangster"] = 1,
            ["gang"] = 1,
            ["mafia"] = 2
        }
    }
}

-- Enhanced Notification System
Config.Notifications = {
    position = 'top-right',
    duration = 5000,
    sound = true,
    defaultIcon = 'info-circle',
    enhancedNotifications = true, -- Use rich notifications with metadata
    bankDepositSound = true, -- Play special sound for bank deposits
    disciplineEffects = true -- Show visual effects for discipline actions
}

-- Enhanced Girl System
Config.GirlSystem = {
    maxGirls = 15,
    basePrice = 5000,
    priceRange = 2000,
    workDuration = 30,
    workCooldown = 15,
    stopWorkingPenalty = 0.2, -- 20% earnings penalty for stopping early
    attitudeDevelopmentChance = 0.001, -- Base chance per check
    attributes = {
        minValue = 10,
        maxValue = 100,
        levelUpCost = 1000,
        levelUpIncrement = 5
    },
    girlTypes = {
        ["Streetwalker"] = {
            basePrice = 3000,
            baseEarnings = 100,
            attributes = {
                appearance = {min = 10, max = 70},
                performance = {min = 10, max = 80},
                loyalty = {min = 10, max = 60},
                discretion = {min = 10, max = 50}
            }
        },
        ["Escort"] = {
            basePrice = 7000,
            baseEarnings = 200,
            attributes = {
                appearance = {min = 40, max = 90},
                performance = {min = 30, max = 90},
                loyalty = {min = 20, max = 70},
                discretion = {min = 30, max = 80}
            }
        },
        ["High-Class"] = {
            basePrice = 12000,
            baseEarnings = 350,
            attributes = {
                appearance = {min = 70, max = 100},
                performance = {min = 60, max = 100},
                loyalty = {min = 30, max = 80},
                discretion = {min = 60, max = 100}
            }
        },
        ["VIP"] = {
            basePrice = 20000,
            baseEarnings = 500,
            attributes = {
                appearance = {min = 85, max = 100},
                performance = {min = 80, max = 100},
                loyalty = {min = 50, max = 90},
                discretion = {min = 80, max = 100}
            }
        }
    },
    names = {
        "Amber", "Bella", "Candy", "Diamond", "Emerald", "Foxy", "Ginger", "Honey", 
        "Ivy", "Jasmine", "Kitty", "Lola", "Misty", "Nicky", "Orchid", "Peach", 
        "Queen", "Ruby", "Sapphire", "Tiffany", "Velvet", "Willow", "Xena", "Yasmine", "Zoe",
        "Angel", "Brandy", "Carmen", "Destiny", "Eve", "Faith", "Grace", "Heaven"
    },
    nationalities = {
        "American", "Russian", "Brazilian", "French", "Italian", "Japanese", 
        "Korean", "Spanish", "Ukrainian", "Colombian", "Canadian", "Australian",
        "British", "German", "Swedish", "Dutch", "Polish", "Czech"
    }
}

-- Enhanced Happiness System
Config.HappinessSystem = {
    enabled = true,
    decayRate = 1,
    workDecayRate = 2,
    baseHappiness = 50,
    criticalLevel = 10, -- Below this level, girl may leave
    warningLevel = 25, -- Below this level, show warnings
    effects = {
        earnings = {
            veryLow = 0.5,   -- 0-20 happiness
            low = 0.75,      -- 21-40 happiness
            normal = 1.0,    -- 41-60 happiness
            high = 1.25,     -- 61-80 happiness
            veryHigh = 1.5   -- 81-100 happiness
        },
        loyalty = {
            veryLow = -2,    -- loyalty loss per day
            low = -1,
            normal = 0,
            high = 1,        -- loyalty gain per day
            veryHigh = 2
        },
        attitudeChance = {
            veryLow = 0.1,   -- 10% chance of developing attitude
            low = 0.05,      -- 5% chance
            normal = 0.01,   -- 1% chance
            high = 0.005,    -- 0.5% chance
            veryHigh = 0.001 -- 0.1% chance
        }
    },
    activities = {
        ["Shopping"] = {
            displayName = "Shopping Spree",
            description = "Take your girl on a luxury shopping trip",
            cost = 500,
            happinessGain = 15,
            duration = 60,
            cooldown = 720
        },
        ["Spa Day"] = {
            displayName = "Spa & Wellness",
            description = "Pamper your girl with a full spa treatment",
            cost = 1000,
            happinessGain = 25,
            duration = 120,
            cooldown = 1440
        },
        ["Night Out"] = {
            displayName = "Night on the Town",
            description = "Take your girl out for drinks and entertainment",
            cost = 750,
            happinessGain = 20,
            duration = 180,
            cooldown = 1080
        },
        ["Vacation"] = {
            displayName = "Weekend Getaway",
            description = "Send your girl on a relaxing vacation",
            cost = 3000,
            happinessGain = 50,
            duration = 1440,
            cooldown = 4320
        },
        ["Fine Dining"] = {
            displayName = "Fine Dining",
            description = "Treat your girl to an expensive dinner",
            cost = 300,
            happinessGain = 10,
            duration = 30,
            cooldown = 480
        },
        ["Concert"] = {
            displayName = "Concert Tickets",
            description = "Buy tickets for a premium concert experience",
            cost = 800,
            happinessGain = 18,
            duration = 90,
            cooldown = 900
        }
    }
}

-- Enhanced NPC Interaction System with Discipline
Config.NPCInteraction = {
    interactionDistance = 3.0,
    minPrice = 50,
    maxPrice = 1000,
    services = {
        {name = "Quick Service", duration = 60, basePrice = 100, performanceMultiplier = 0.8},
        {name = "Standard Service", duration = 120, basePrice = 200, performanceMultiplier = 1.0},
        {name = "Premium Service", duration = 180, basePrice = 300, performanceMultiplier = 1.2},
        {name = "VIP Experience", duration = 300, basePrice = 500, performanceMultiplier = 1.5},
        {name = "Overnight Service", duration = 480, basePrice = 800, performanceMultiplier = 2.0}
    },
    npcTypes = {
        {model = "a_m_m_business_01", name = "Businessman", priceMultiplier = 1.5, preferredService = "Premium Service"},
        {model = "a_m_m_hillbilly_01", name = "Hillbilly", priceMultiplier = 0.7, preferredService = "Quick Service"},
        {model = "a_m_m_salton_01", name = "Local", priceMultiplier = 0.8, preferredService = "Standard Service"},
        {model = "a_m_m_skater_01", name = "Skater", priceMultiplier = 0.9, preferredService = "Quick Service"},
        {model = "a_m_m_tourist_01", name = "Tourist", priceMultiplier = 1.2, preferredService = "Standard Service"},
        {model = "a_m_y_business_01", name = "Young Executive", priceMultiplier = 1.3, preferredService = "Premium Service"},
        {model = "a_m_y_clubcust_01", name = "Club Patron", priceMultiplier = 1.1, preferredService = "VIP Experience"},
        {model = "a_m_y_vinewood_01", name = "Vinewood Guy", priceMultiplier = 1.4, preferredService = "VIP Experience"}
    },
    
    -- Enhanced Following System
    Following = {
        enabled = true,
        maxFollowers = 3,
        maxDistance = 10.0,
        updateInterval = 1000,
        vehicleSupport = true, -- Girls can enter vehicles
        smartPathfinding = true, -- Better AI pathfinding
        commands = {
            followMe = "followme",
            stopFollow = "stopfollow",
            stopAllFollow = "stopallfollow"
        }
    },
    
    -- Enhanced Discipline System
    Discipline = {
        enabled = true,
        types = {
            verbal = {
                name = "Verbal Warning",
                description = "Give a stern talking to",
                loyaltyChange = -5,
                fearChange = 5,
                happinessChange = -2,
                animation = "misscarsteal4@actor",
                animationDict = "actor_berating_loop",
                duration = 3000,
                cooldown = 60000, -- 1 minute
                soundEffect = "SCRIPTED_SCANNER_REPORT_GUNFIRE_01"
            },
            slap = {
                name = "Slap",
                description = "Show physical dominance with a slap",
                loyaltyChange = -10,
                fearChange = 15,
                happinessChange = -5,
                animation = "melee@unarmed@streamed_variations",
                animationDict = "plyr_takedown_front_slap",
                duration = 2000,
                cooldown = 300000, -- 5 minutes
                soundEffect = "SLAP",
                visualEffect = true -- Screen shake and particle effect
            },
            threaten = {
                name = "Threaten",
                description = "Intimidate with serious consequences",
                loyaltyChange = -20,
                fearChange = 25,
                happinessChange = -10,
                animation = "mp_player_int_upperfinger",
                animationDict = "mp_player_int_finger_01_enter",
                duration = 4000,
                cooldown = 600000, -- 10 minutes
                soundEffect = "SCRIPTED_SCANNER_REPORT_GUNFIRE_02"
            },
            push = {
                name = "Push",
                description = "Push the girl to show dominance",
                loyaltyChange = -15,
                fearChange = 20,
                happinessChange = -8,
                animation = "melee@unarmed@streamed_variations",
                animationDict = "plyr_takedown_front_backhand",
                duration = 2000,
                cooldown = 300000, -- 5 minutes
                soundEffect = "PUNCH_CUFF",
                visualEffect = true
            },
            grab = {
                name = "Grab",
                description = "Grab the girl by the collar",
                loyaltyChange = -8,
                fearChange = 12,
                happinessChange = -5,
                animation = "missmic4",
                animationDict = "michael_tux_fidget",
                duration = 2500,
                cooldown = 180000, -- 3 minutes
                soundEffect = "CLOTHES_SHOP_ENTER",
                visualEffect = false
            },
            reward = {
                name = "Small Reward",
                description = "Give a small gift to improve mood",
                loyaltyChange = 5,
                fearChange = -3,
                happinessChange = 8,
                cost = 100, -- Cost money for rewards
                animation = "mp_common",
                animationDict = "givetake1_a",
                duration = 2000,
                cooldown = 180000, -- 3 minutes
                soundEffect = "PICK_UP"
            }
        },
        attitudeCorrection = {
            verbal = 0.3,   -- 30% chance to correct attitude
            slap = 0.6,     -- 60% chance to correct attitude
            threaten = 0.9, -- 90% chance to correct attitude
            reward = 0.1    -- 10% chance (rewards work differently)
        },
        perks = {
            -- Discipline perks that can be unlocked
            gentleTouch = {
                name = "Gentle Touch",
                description = "Reduce negative effects of discipline by 25%",
                cost = 1500,
                effect = {type = "discipline_reduction", value = 0.25}
            },
            psychologist = {
                name = "Psychology Degree",
                description = "50% better chance of attitude correction",
                cost = 3000,
                effect = {type = "attitude_correction_boost", value = 0.5}
            },
            fearMaster = {
                name = "Master of Fear",
                description = "Discipline actions have 25% more fear impact",
                cost = 2000,
                effect = {type = "fear_boost", value = 0.25}
            }
        }
    }
}

-- Enhanced Money & Banking System
Config.BankingSystem = {
    enabled = true,
    bankDeposits = true, -- Automatically deposit earnings to bank
    transactionHistory = true, -- Track all transactions
    largeWithdrawalThreshold = 10000, -- Require confirmation for amounts above this
    bankingFees = {
        enabled = false, -- Enable banking fees
        withdrawalFee = 0.02, -- 2% fee on withdrawals
        depositFee = 0.01 -- 1% fee on deposits
    },
    notifications = {
        showAmount = true,
        showSource = true,
        showBalance = false, -- Don't show balance for security
        enhancedDetails = true
    }
}

-- Enhanced Reputation System
Config.ReputationSystem = {
    enabled = true,
    levels = {
        {name = "Rookie Pimp", threshold = 0, maxGirls = 3, perks = {}},
        {name = "Street Pimp", threshold = 1000, maxGirls = 5, perks = {"basic_negotiation"}},
        {name = "Established Pimp", threshold = 3000, maxGirls = 7, perks = {"territory_access"}},
        {name = "Professional Pimp", threshold = 7000, maxGirls = 10, perks = {"vip_clients"}},
        {name = "Master Pimp", threshold = 15000, maxGirls = 15, perks = {"empire_builder"}},
        {name = "Legendary Pimp", threshold = 30000, maxGirls = 20, perks = {"untouchable"}}
    },
    earnings = {
        basePoints = 10,
        girlQualityMultiplier = 0.1,
        locationMultiplier = {
            lowRisk = 0.8,
            mediumRisk = 1.0,
            highRisk = 1.5
        },
        disciplinePoints = 2, -- Points for successful discipline
        attitudeCorrectionBonus = 5 -- Bonus points for fixing attitude
    },
    decay = {
        enabled = true,
        gracePeriod = 7,
        dailyDecay = 50,
        minReputation = 0
    },
    leaderboard = {
        enabled = true,
        refreshInterval = 10,
        displayCount = 10
    },
    perks = {
        -- Business perks (enhanced)
        business = {
            {
                id = "earnings_boost_1",
                name = "Earnings Boost I",
                description = "Increase all earnings by 5%",
                icon = "dollar-sign",
                cost = 500,
                effect = {type = "earnings_multiplier", value = 0.05},
                requiredLevel = 1
            },
            {
                id = "earnings_boost_2",
                name = "Earnings Boost II",
                description = "Increase all earnings by 10%",
                icon = "dollar-sign",
                cost = 1500,
                effect = {type = "earnings_multiplier", value = 0.10},
                requiredLevel = 2,
                requiredPerk = "earnings_boost_1"
            },
            {
                id = "earnings_boost_3",
                name = "Earnings Boost III",
                description = "Increase all earnings by 15%",
                icon = "dollar-sign",
                cost = 3500,
                effect = {type = "earnings_multiplier", value = 0.15},
                requiredLevel = 3,
                requiredPerk = "earnings_boost_2"
            },
            {
                id = "negotiation_skill_1",
                name = "Negotiation Skills I",
                description = "10% better chance of successful price negotiations",
                icon = "comments-dollar",
                cost = 800,
                effect = {type = "negotiation_bonus", value = 0.10},
                requiredLevel = 1
            },
            {
                id = "negotiation_skill_2",
                name = "Negotiation Skills II",
                description = "20% better chance of successful price negotiations",
                icon = "comments-dollar",
                cost = 2000,
                effect = {type = "negotiation_bonus", value = 0.20},
                requiredLevel = 2,
                requiredPerk = "negotiation_skill_1"
            },
            {
                id = "premium_clients",
                name = "Premium Client Network",
                description = "Attract higher-paying clients",
                icon = "user-tie",
                cost = 2500,
                effect = {type = "client_quality_boost", value = 0.15},
                requiredLevel = 3
            }
        },
        
        -- Protection perks (enhanced)
        protection = {
            {
                id = "police_protection_1",
                name = "Police Protection I",
                description = "15% reduced chance of police interference",
                icon = "shield-alt",
                cost = 1000,
                effect = {type = "police_protection", value = 0.15},
                requiredLevel = 1
            },
            {
                id = "police_protection_2",
                name = "Police Protection II",
                description = "30% reduced chance of police interference",
                icon = "shield-alt",
                cost = 2500,
                effect = {type = "police_protection", value = 0.30},
                requiredLevel = 2,
                requiredPerk = "police_protection_1"
            },
            {
                id = "territory_defense_1",
                name = "Territory Defense I",
                description = "10% bonus to territory defense",
                icon = "map-marker-alt",
                cost = 1200,
                effect = {type = "territory_defense", value = 0.10},
                requiredLevel = 2
            },
            {
                id = "territory_defense_2",
                name = "Territory Defense II",
                description = "25% bonus to territory defense",
                icon = "map-marker-alt",
                cost = 3000,
                effect = {type = "territory_defense", value = 0.25},
                requiredLevel = 3,
                requiredPerk = "territory_defense_1"
            },
            {
                id = "bodyguard",
                name = "Personal Bodyguard",
                description = "Reduce risk of attacks by 40%",
                icon = "user-shield",
                cost = 5000,
                effect = {type = "attack_protection", value = 0.40},
                requiredLevel = 4
            }
        },
        
        -- Girl management perks (enhanced)
        girl_management = {
            {
                id = "happiness_decay_1",
                name = "Happiness Management I",
                description = "15% slower happiness decay for all girls",
                icon = "smile",
                cost = 800,
                effect = {type = "happiness_decay_reduction", value = 0.15},
                requiredLevel = 1
            },
            {
                id = "happiness_decay_2",
                name = "Happiness Management II",
                description = "30% slower happiness decay for all girls",
                icon = "smile",
                cost = 2000,
                effect = {type = "happiness_decay_reduction", value = 0.30},
                requiredLevel = 2,
                requiredPerk = "happiness_decay_1"
            },
            {
                id = "loyalty_boost_1",
                name = "Loyalty Boost I",
                description = "Girls gain loyalty 10% faster",
                icon = "heart",
                cost = 1000,
                effect = {type = "loyalty_gain_boost", value = 0.10},
                requiredLevel = 1
            },
            {
                id = "loyalty_boost_2",
                name = "Loyalty Boost II",
                description = "Girls gain loyalty 25% faster",
                icon = "heart",
                cost = 2500,
                effect = {type = "loyalty_gain_boost", value = 0.25},
                requiredLevel = 3,
                requiredPerk = "loyalty_boost_1"
            },
            {
                id = "girl_training_1",
                name = "Girl Training I",
                description = "Girls improve attributes 10% faster",
                icon = "graduation-cap",
                cost = 1500,
                effect = {type = "attribute_gain_boost", value = 0.10},
                requiredLevel = 2
            },
            {
                id = "girl_training_2",
                name = "Girl Training II",
                description = "Girls improve attributes 25% faster",
                icon = "graduation-cap",
                cost = 3500,
                effect = {type = "attribute_gain_boost", value = 0.25},
                requiredLevel = 4,
                requiredPerk = "girl_training_1"
            },
            {
                id = "discipline_master",
                name = "Discipline Master",
                description = "25% better discipline effectiveness",
                icon = "hand-paper",
                cost = 2000,
                effect = {type = "discipline_effectiveness", value = 0.25},
                requiredLevel = 2
            }
        },
        
        -- Territory perks (enhanced)
        territory = {
            {
                id = "territory_discovery_1",
                name = "Territory Discovery I",
                description = "Reveal 2 random territories on the map",
                icon = "map",
                cost = 1000,
                effect = {type = "territory_discovery", value = 2},
                requiredLevel = 1,
                oneTime = true
            },
            {
                id = "territory_discovery_2",
                name = "Territory Discovery II",
                description = "Reveal 3 more random territories on the map",
                icon = "map",
                cost = 2500,
                effect = {type = "territory_discovery", value = 3},
                requiredLevel = 2,
                requiredPerk = "territory_discovery_1",
                oneTime = true
            },
            {
                id = "vip_territory_discovery",
                name = "VIP Territory Discovery",
                description = "Reveal the location of a premium VIP territory",
                icon = "gem",
                cost = 5000,
                effect = {type = "vip_territory_discovery", value = 1},
                requiredLevel = 3,
                oneTime = true
            },
            {
                id = "territory_control_1",
                name = "Territory Control I",
                description = "10% faster territory control gain",
                icon = "flag",
                cost = 1500,
                effect = {type = "territory_control_boost", value = 0.10},
                requiredLevel = 2
            },
            {
                id = "territory_control_2",
                name = "Territory Control II",
                description = "25% faster territory control gain",
                icon = "flag",
                cost = 3500,
                effect = {type = "territory_control_boost", value = 0.25},
                requiredLevel = 3,
                requiredPerk = "territory_control_1"
            }
        },
        
        -- Special perks (enhanced)
        special = {
            {
                id = "fast_travel",
                name = "Fast Travel",
                description = "Ability to fast travel between controlled territories",
                icon = "bolt",
                cost = 5000,
                effect = {type = "fast_travel", value = true},
                requiredLevel = 4
            },
            {
                id = "girl_recovery",
                name = "Enhanced Recovery",
                description = "Girls recover 50% faster from injuries",
                icon = "first-aid",
                cost = 3000,
                effect = {type = "recovery_boost", value = 0.50},
                requiredLevel = 3
            },
            {
                id = "vip_clients",
                name = "VIP Client Network",
                description = "Occasional VIP clients that pay 3x the normal rate",
                icon = "user-tie",
                cost = 7500,
                effect = {type = "vip_clients", value = 0.05},
                requiredLevel = 4
            },
            {
                id = "reputation_shield",
                name = "Reputation Shield",
                description = "50% slower reputation decay",
                icon = "shield",
                cost = 4000,
                effect = {type = "reputation_decay_reduction", value = 0.50},
                requiredLevel = 3
            },
            {
                id = "empire_builder",
                name = "Empire Builder",
                description = "Can own 25% more girls than normal",
                icon = "crown",
                cost = 10000,
                effect = {type = "max_girls_boost", value = 0.25},
                requiredLevel = 5
            }
        }
    }
}

-- Enhanced Territory System
Config.TerritorySystem = {
    enabled = true,
    contestDuration = 15,
    contestCooldown = 60,
    controlDecay = 0.05,
    proximityRequirement = 50.0,
    workingGirlSpawnDistance = 5.0,
    territoryPrice = 25000, -- Base price for territories
    upkeepEnabled = true, -- Enable territory upkeep costs
    upkeepInterval = 7, -- Days between upkeep payments (weekly)
    upkeepCost = 5000, -- Base upkeep cost
    upkeepGracePeriod = 3, -- Days of grace period before territory becomes contested
    upkeepNotificationTime = 24, -- Hours before upkeep is due to send notification
    maxGirlsPerTerritory = 3, -- Maximum number of girls that can work in a territory
    controlBenefits = {
        earningsBonus = 0.5,
        riskReduction = 0.5,
        reputationBonus = 0.3
    },
    
    -- Enhanced upgrade paths
    upgrades = {
        security = {
            {
                level = 1,
                name = "Basic Security",
                description = "Basic security measures to protect your girls",
                cost = 5000,
                effect = {
                    security_boost = 0.15,
                    attack_resistance = 0.10,
                    girl_safety = 0.20
                }
            },
            {
                level = 2,
                name = "Enhanced Security",
                description = "Better security with occasional guard patrols",
                cost = 15000,
                effect = {
                    security_boost = 0.30,
                    attack_resistance = 0.25,
                    guard_presence = true,
                    girl_safety = 0.40
                }
            },
            {
                level = 3,
                name = "Premium Security",
                description = "Full-time security personnel and surveillance",
                cost = 35000,
                effect = {
                    security_boost = 0.50,
                    attack_resistance = 0.40,
                    guard_presence = true,
                    surveillance = true,
                    girl_safety = 0.60
                }
            }
        },
        
        visibility = {
            {
                level = 1,
                name = "Basic Advertising",
                description = "Simple advertising to attract more clients",
                cost = 3000,
                effect = {
                    client_frequency = 0.15,
                    visibility_boost = 0.10,
                    earnings_boost = 0.05
                }
            },
            {
                level = 2,
                name = "Enhanced Advertising",
                description = "Better advertising with social media presence",
                cost = 10000,
                effect = {
                    client_frequency = 0.30,
                    visibility_boost = 0.25,
                    client_quality_boost = 0.10,
                    earnings_boost = 0.15
                }
            },
            {
                level = 3,
                name = "Premium Advertising",
                description = "High-end marketing targeting wealthy clients",
                cost = 25000,
                effect = {
                    client_frequency = 0.50,
                    visibility_boost = 0.40,
                    client_quality_boost = 0.25,
                    vip_client_chance = 0.05,
                    earnings_boost = 0.25
                }
            }
        },
        
        comfort = {
            {
                level = 1,
                name = "Basic Amenities",
                description = "Basic comfort improvements for your girls",
                cost = 4000,
                effect = {
                    happiness_decay_reduction = 0.10,
                    earnings_boost = 0.05,
                    girl_satisfaction = 0.15
                }
            },
            {
                level = 2,
                name = "Enhanced Comfort",
                description = "Better amenities and working conditions",
                cost = 12000,
                effect = {
                    happiness_decay_reduction = 0.25,
                    earnings_boost = 0.15,
                    recovery_boost = 0.10,
                    girl_satisfaction = 0.30
                }
            },
            {
                level = 3,
                name = "Luxury Accommodations",
                description = "High-end accommodations attracting better clients",
                cost = 30000,
                effect = {
                    happiness_decay_reduction = 0.40,
                    earnings_boost = 0.25,
                    recovery_boost = 0.25,
                    happiness_gain = 1,
                    girl_satisfaction = 0.50
                }
            }
        },
        
        operations = {
            {
                level = 1,
                name = "Basic Operations",
                description = "Improved operational efficiency",
                cost = 5000,
                effect = {
                    earnings_boost = 0.10,
                    reputation_boost = 0.05,
                    efficiency = 0.15
                }
            },
            {
                level = 2,
                name = "Enhanced Operations",
                description = "Better management and client handling",
                cost = 15000,
                effect = {
                    earnings_boost = 0.20,
                    reputation_boost = 0.15,
                    negotiation_boost = 0.10,
                    efficiency = 0.30
                }
            },
            {
                level = 3,
                name = "Premium Operations",
                description = "High-end operation with VIP services",
                cost = 35000,
                effect = {
                    earnings_boost = 0.35,
                    reputation_boost = 0.25,
                    negotiation_boost = 0.25,
                    vip_client_chance = 0.10,
                    efficiency = 0.50
                }
            }
        }
    },
    
    -- Enhanced raid settings
    raids = {
        enabled = true,
        npcRaidChance = 0.05,
        npcRaidCooldown = 12,
        playerRaidCooldown = 4,
        defenseSuccessBaseChance = 0.5,
        securityImpact = 0.5,
        failureConsequences = {
            controlLoss = 0.2,
            earningsLoss = 0.3,
            girlHappinessLoss = 10,
            girlInjuryChance = 0.3,
            reputationLoss = 50
        }
    }
}

-- Enhanced Work Locations
Config.WorkLocations = {
    {
        name = "Red Light District",
        coords = vector3(112.0, -1286.7, 28.3),
        radius = 50.0,
        riskLevel = "medium",
        earningsMultiplier = 1.0,
        clientDensity = 1.0,
        priceMultiplier = 1.0,
        clientTypes = {"regular", "budget"},
        blip = {
            sprite = 280,
            color = 1,
            scale = 0.8,
            label = "Red Light District"
        }
    },
    {
        name = "Vinewood Boulevard",
        coords = vector3(312.8, 218.9, 104.5),
        radius = 70.0,
        riskLevel = "low",
        earningsMultiplier = 1.2,
        clientDensity = 0.8,
        priceMultiplier = 1.3,
        clientTypes = {"regular", "wealthy"},
        blip = {
            sprite = 280,
            color = 2,
            scale = 0.8,
            label = "Vinewood Boulevard"
        }
    },
    {
        name = "Vespucci Beach",
        coords = vector3(-1183.3, -1554.5, 4.2),
        radius = 80.0,
        riskLevel = "low",
        earningsMultiplier = 1.1,
        clientDensity = 1.2,
        priceMultiplier = 1.1,
        clientTypes = {"regular", "tourist"},
        blip = {
            sprite = 280,
            color = 3,
            scale = 0.8,
            label = "Vespucci Beach"
        }
    },
    {
        name = "South Los Santos",
        coords = vector3(84.9, -1952.4, 20.8),
        radius = 60.0,
        riskLevel = "high",
        earningsMultiplier = 0.8,
        clientDensity = 0.7,
        priceMultiplier = 0.8,
        clientTypes = {"budget", "regular"},
        blip = {
            sprite = 280,
            color = 1,
            scale = 0.8,
            label = "South Los Santos"
        }
    },
    {
        name = "Downtown Vinewood",
        coords = vector3(21.3, 221.7, 109.6),
        radius = 50.0,
        riskLevel = "medium",
        earningsMultiplier = 1.3,
        clientDensity = 0.9,
        priceMultiplier = 1.4,
        clientTypes = {"regular", "wealthy"},
        blip = {
            sprite = 280,
            color = 2,
            scale = 0.8,
            label = "Downtown Vinewood"
        }
    },
    {
        name = "Casino District",
        coords = vector3(925.3, 46.1, 80.9),
        radius = 40.0,
        riskLevel = "low",
        earningsMultiplier = 1.5,
        clientDensity = 0.6,
        priceMultiplier = 1.8,
        clientTypes = {"wealthy", "vip"},
        blip = {
            sprite = 280,
            color = 5,
            scale = 0.8,
            label = "Casino District"
        }
    }
}

-- Enhanced Hiring Locations
Config.HiringLocations = {
    {
        name = "Vanilla Unicorn",
        coords = vector3(127.2, -1284.3, 29.3),
        girlTypes = {"Streetwalker", "Escort"},
        blip = {
            sprite = 121,
            color = 48,
            scale = 0.8,
            label = "Girl Hiring"
        }
    },
    {
        name = "Bahama Mamas",
        coords = vector3(-1388.9, -586.7, 30.2),
        girlTypes = {"Escort", "High-Class"},
        blip = {
            sprite = 121,
            color = 48,
            scale = 0.8,
            label = "Girl Hiring"
        }
    },
    {
        name = "Casino Penthouse",
        coords = vector3(969.1, 72.4, 115.0),
        girlTypes = {"High-Class", "VIP"},
        blip = {
            sprite = 121,
            color = 5,
            scale = 0.8,
            label = "VIP Girl Hiring"
        }
    }
}

-- Enhanced Dynamic Pricing System
Config.DynamicPricing = {
    enabled = true,
    baseMultipliers = {
        appearance = 0.3,
        performance = 0.4,
        discretion = 0.2,
        reputation = 0.1
    },
    clientTypes = {
        budget = {
            priceMultiplier = 0.7,
            negotiationRange = 0.25,
            happinessBonus = 5
        },
        regular = {
            priceMultiplier = 1.0,
            negotiationRange = 0.1,
            happinessBonus = 10
        },
        wealthy = {
            priceMultiplier = 1.5,
            negotiationRange = 0.05,
            happinessBonus = 15
        },
        vip = {
            priceMultiplier = 2.5,
            negotiationRange = 0.02,
            happinessBonus = 25
        }
    },
    timeOfDay = {
        morning = 0.8,   -- 6AM-12PM
        afternoon = 1.0, -- 12PM-6PM
        evening = 1.2,   -- 6PM-12AM
        night = 1.5      -- 12AM-6AM
    },
    locationTiers = {
        low = 0.8,
        standard = 1.0,
        premium = 1.5,
        exclusive = 2.0
    },
    demandFactors = {
        enabled = true,
        highDemandBonus = 1.3,
        lowDemandPenalty = 0.8
    }
}

-- Enhanced Girl Models
Config.GirlModels = {
    "u_f_y_poppymich",
    "s_f_y_stripper_01",
    "s_f_y_stripper_02",
    "csb_stripper_01",
    "csb_stripper_02"
}

-- Enhanced Client Models
Config.ClientModels = {
    "a_m_m_business_01",
    "a_m_m_bevhills_01",
    "a_m_m_bevhills_02",
    "a_m_m_eastsa_01",
    "a_m_m_eastsa_02",
    "a_m_m_farmer_01",
    "a_m_m_fatlatin_01",
    "a_m_m_genfat_01",
    "a_m_m_genfat_02",
    "a_m_m_golfer_01",
    "a_m_m_hasjew_01",
    "a_m_m_hillbilly_01",
    "a_m_m_hillbilly_02",
    "a_m_m_indian_01",
    "a_m_m_ktown_01",
    "a_m_m_malibu_01",
    "a_m_m_mexcntry_01",
    "a_m_m_mexlabor_01",
    "a_m_m_og_boss_01",
    "a_m_m_paparazzi_01",
    "a_m_m_polynesian_01",
    "a_m_m_prolhost_01",
    "a_m_m_rurmeth_01",
    "a_m_m_salton_01",
    "a_m_m_salton_02",
    "a_m_m_salton_03",
    "a_m_m_salton_04",
    "a_m_m_skater_01",
    "a_m_m_skidrow_01",
    "a_m_m_socenlat_01",
    "a_m_m_soucent_01",
    "a_m_m_soucent_02",
    "a_m_m_soucent_03",
    "a_m_m_soucent_04",
    "a_m_m_stlat_02",
    "a_m_m_tennis_01",
    "a_m_m_tourist_01",
    "a_m_m_tramp_01",
    "a_m_m_trampbeac_01",
    "a_m_m_tranvest_01",
    "a_m_m_tranvest_02",
    "a_m_o_acult_01",
    "a_m_o_acult_02",
    "a_m_o_beach_01",
    "a_m_o_genstreet_01",
    "a_m_o_ktown_01",
    "a_m_y_clubcust_01",
    "a_m_y_clubcust_02",
    "a_m_y_clubcust_03"
}

-- Show client blips on the map
Config.ShowClientBlips = true

-- Key bindings
Config.KeyBindings = {
    openMenu = 'F6', -- Key to open the pimp menu
    startPimping = 'F7' -- Key to start pimping mode
}

-- Return the config
return Config
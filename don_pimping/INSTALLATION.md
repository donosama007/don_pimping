# Installation Guide - ESX Pimp Management System

This guide will walk you through the process of installing and configuring the ESX Pimp Management System on your FiveM server.

## Prerequisites

Before installing the script, make sure you have the following:

- A running FiveM server with ESX or QBCore framework
- Database access (MySQL)
- Server access to install resources
- The following dependencies installed:
  - [ox_lib](https://github.com/overextended/ox_lib)
  - [oxmysql](https://github.com/overextended/oxmysql)

## Step 1: Download and Extract

1. Download the latest release of the ESX Pimp Management System
2. Extract the files to your server's resources folder
3. Rename the folder to `esx_pimping` (or any name you prefer)

## Step 2: Database Setup

1. Connect to your MySQL database using your preferred method (phpMyAdmin, MySQL Workbench, command line, etc.)
2. Import the SQL file located in the `sql` folder:

   **Using phpMyAdmin:**
   - Open phpMyAdmin
   - Select your database
   - Click on the "Import" tab
   - Click "Choose File" and select the `setup.sql` file
   - Click "Go" to import the file

   **Using MySQL command line:**
   ```bash
   mysql -u username -p database_name < /path/to/setup.sql
   ```

3. Verify that the following tables have been created:
   - `pimp_players`
   - `pimp_girls`
   - `pimp_earnings`
   - `pimp_items`
   - `pimp_cooldowns`
   - `pimp_territory`
   - `pimp_girl_reputation_history`
   - `pimp_service_prices`
   - `pimp_location_pricing`
   - `pimp_price_history`
   - `pimp_girl_events`
   - `pimp_shop_history`
   - `pimp_transactions`
   - `pimp_girl_activities`

## Step 3: Configure the Script

1. Open the `config.lua` file in your preferred text editor
2. Configure the script according to your server's needs:

   **Framework Configuration:**
   ```lua
   Config.Framework = "esx" -- Options: "qb-core", "esx", "custom"
   ```

   **Permission System:**
   ```lua
   Config.PermissionSystem = {
       enabled = true,
       whitelist = {
           enabled = true,
           allowedJobs = {
               ["pimp"] = true,
               ["criminal"] = true,
               ["gangster"] = true
           },
           requiredJobGrades = {
               ["pimp"] = 0,
               ["criminal"] = 2,
               ["gangster"] = 3
           }
       }
   }
   ```

   **Work Locations:**
   ```lua
   Config.WorkLocations = {
       {
           name = "Red Light District",
           coords = vector3(112.0, -1286.7, 28.3),
           radius = 50.0,
           riskLevel = "medium",
           earningsMultiplier = 1.0,
           clientDensity = 1.0,
           blip = {
               sprite = 280,
               color = 1,
               scale = 0.8,
               label = "Red Light District"
           }
       },
       -- Add more locations as needed
   }
   ```

   **Hiring Locations:**
   ```lua
   Config.HiringLocations = {
       {
           name = "Vanilla Unicorn",
           coords = vector3(127.2, -1284.3, 29.3),
           blip = {
               sprite = 121,
               color = 48,
               scale = 0.8,
               label = "Girl Hiring"
           }
       },
       -- Add more locations as needed
   }
   ```

3. Save the configuration file

## Step 4: Add to server.cfg

1. Open your server's `server.cfg` file
2. Add the following lines:

   ```
   ensure oxmysql
   ensure ox_lib
   ensure esx_pimping
   ```

   **Note:** Make sure to add these lines after your framework resources (ESX or QBCore)

## Step 5: Create Job (Optional)

If you want to use the job-based permission system, you need to create a "pimp" job in your framework:

**For ESX:**
1. Open your database management tool
2. Navigate to the `jobs` table
3. Add a new job:
   ```sql
   INSERT INTO `jobs` (`name`, `label`) VALUES ('pimp', 'Pimp');
   ```
4. Add job grades:
   ```sql
   INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
   ('pimp', 0, 'rookie', 'Rookie Pimp', 200, '{}', '{}'),
   ('pimp', 1, 'experienced', 'Experienced Pimp', 400, '{}', '{}'),
   ('pimp', 2, 'professional', 'Professional Pimp', 600, '{}', '{}'),
   ('pimp', 3, 'boss', 'Master Pimp', 800, '{}', '{}');
   ```

**For QBCore:**
1. Open your `qb-core/shared/jobs.lua` file
2. Add the pimp job:
   ```lua
   ["pimp"] = {
       label = "Pimp",
       defaultDuty = true,
       grades = {
           ['0'] = {
               name = "Rookie Pimp",
               payment = 200
           },
           ['1'] = {
               name = "Experienced Pimp",
               payment = 400
           },
           ['2'] = {
               name = "Professional Pimp",
               payment = 600
           },
           ['3'] = {
               name = "Master Pimp",
               payment = 800,
               isboss = true
           },
       }
   }
   ```

## Step 6: Start Your Server

1. Start or restart your FiveM server
2. Check the server console for any errors related to the script
3. If everything is working correctly, you should see:
   ```
   ^2Database initialization completed^7
   ^2Pimp Management System initialized^7
   ```

## Step 7: In-Game Testing

1. Join your server
2. Use the `/pimp` command to open the pimp menu
3. Visit a hiring location to purchase girls
4. Test the various features of the script

## Troubleshooting

### Database Issues

If you encounter database errors:

1. Check that oxmysql is properly installed and running
2. Verify that the database tables were created correctly
3. Check the server console for specific error messages
4. Make sure your database user has the necessary permissions

### Permission Issues

If players cannot access the pimp menu:

1. Check the permission configuration in `config.lua`
2. Verify that players have the correct job and job grade
3. Check the server console for permission-related messages
4. Try temporarily disabling the permission system for testing

### Script Not Loading

If the script doesn't load:

1. Check that all dependencies are installed and loaded
2. Verify that the script is listed in your `server.cfg`
3. Check the server console for error messages
4. Make sure the script is loaded after its dependencies

### Performance Issues

If you experience performance issues:

1. Enable debug mode in the configuration to identify bottlenecks
2. Check if there are too many NPCs being processed
3. Reduce the radius of work locations
4. Optimize the configuration for your server's needs

## Additional Configuration

### Adding Custom Girl Types

To add custom girl types, edit the `Config.GirlSystem.girlTypes` section in `config.lua`:

```lua
Config.GirlSystem.girlTypes = {
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
    ["YourCustomType"] = {
        basePrice = 5000,
        baseEarnings = 150,
        attributes = {
            appearance = {min = 20, max = 80},
            performance = {min = 20, max = 85},
            loyalty = {min = 15, max = 65},
            discretion = {min = 15, max = 60}
        }
    }
}
```

### Adding Custom Work Locations

To add custom work locations, edit the `Config.WorkLocations` section in `config.lua`:

```lua
table.insert(Config.WorkLocations, {
    name = "Your Custom Location",
    coords = vector3(x, y, z),
    radius = 50.0,
    riskLevel = "medium", -- Options: "low", "medium", "high"
    earningsMultiplier = 1.2,
    clientDensity = 1.0,
    blip = {
        sprite = 280,
        color = 1,
        scale = 0.8,
        label = "Your Custom Location"
    }
})
```

## Support

If you need help with installation or configuration, please refer to the following resources:

- Check the README.md file for general information
- Review the CHANGELOG.md file for recent changes
- Join our Discord server for community support
- Open an issue on GitHub for bug reports

## Updating

When updating to a new version:

1. Backup your current configuration
2. Replace all files with the new version
3. Run the SQL update script if provided
4. Restore your custom configuration
5. Restart your server
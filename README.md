# Left 4 World Wide rank
Changes the world wide rank to #1 and served players from a database count

## Requirements
- Sourcemod and metamod

## Usage
1. Download the plugin from the latest release:
[Releases Section](https://github.com/LeandroTheDev/left_4_wwr/releases)

2. Place the compiled .smx file into the following folder on your server: addons/sourcemod/plugins/

3. Create a database with mariadb or mysql
```sql
CREATE mydatabase
USE mydatabase
CREATE TABLE left4dead2 (
    uniqueid VARCHAR(255) NOT NULL PRIMARY KEY,
    value DECIMAL(50, 0) NOT NULL DEFAULT 0
);
```

4. Set up your database in ``addons/sourcemod/configs/databases.cfg``
```
"default"
{
    "driver"    "default"
    "host"      "127.0.0.1"
    "database"  "mydatabase"
    "pass"      "ultrasecret"
}
```

5. Change launching parameters: ``-worldRankDatabase default`` and ``-worldRankTable left4dead2``

6. Run the server

## Compiling

- Use the compiler from sourcemod to compile the left_4_wwr.sp


CREATE DATABASE IF NOT EXISTS tournament_test
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON tournament_test.* TO 'tournament'@'%';

FLUSH PRIVILEGES;

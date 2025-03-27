CREATE TABLE IF NOT EXISTS `marketplace_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `stand_id` int(11) NOT NULL,
  `item_name` varchar(50) NOT NULL,
  `quantity` int(11) NOT NULL,
  `price` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `stand_id` (`stand_id`)
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

CREATE TABLE IF NOT EXISTS `marketplace_stands` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `stand_id` int(11) NOT NULL,
  `owner` varchar(50) NOT NULL,
  `title` varchar(50) NOT NULL,
  `description` varchar(255) NOT NULL,
  `rental_start` timestamp NOT NULL DEFAULT current_timestamp(),
  `rental_end` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `stand_id` (`stand_id`),
  KEY `owner` (`owner`)
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
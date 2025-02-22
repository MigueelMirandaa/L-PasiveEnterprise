CREATE TABLE IF NOT EXISTS lockser_passiveenterprise (
    id INT PRIMARY KEY AUTO_INCREMENT,
    identifier TEXT NOT NULL,
    name TEXT NOT NULL,
    company_name TEXT NOT NULL,
    money_generated_per_hour INT,
    max_quantity INT,
    current_money INT DEFAULT 0,
    coords TEXT NOT NULL
);

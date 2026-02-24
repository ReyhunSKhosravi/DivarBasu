-- ordinary users tables:

CREATE TABLE user (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(150) NOT NULL UNIQUE,
    wallet_balance NUMERIC(12,2) DEFAULT 0 CHECK (wallet_balance >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE address (
    address_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    full_address TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_address_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

CREATE TABLE product_bookmark (
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    bookmarked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, product_id),

    CONSTRAINT fk_product_bookmark_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_product_bookmark_product
        FOREIGN KEY (product_id)
        REFERENCES product(product_id)
        ON DELETE CASCADE
);

CREATE TABLE booth_bookmark (
    user_id INT NOT NULL,
    booth_id INT NOT NULL,
    bookmarked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, booth_id),

    CONSTRAINT fk_booth_bookmark_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_booth_bookmark_booth
        FOREIGN KEY (booth_id)
        REFERENCES booth(booth_id)
        ON DELETE CASCADE
);

-- vip users tables:

CREATE TABLE subscription_plan (
    plan_id SERIAL PRIMARY KEY,

    name VARCHAR(20) UNIQUE NOT NULL
        CHECK (name IN ('1_MONTH','3_MONTH','6_MONTH','1_YEAR','LIFETIME')),

    duration_days INT,

    price NUMERIC(12,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE vip_subscription (
    subscription_id SERIAL PRIMARY KEY,

    user_id INT NOT NULL,

    plan_id INT NOT NULL,

    start_date TIMESTAMP NOT NULL,

    end_date TIMESTAMP,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    FOREIGN KEY (plan_id)
        REFERENCES subscription_plan(plan_id)
);


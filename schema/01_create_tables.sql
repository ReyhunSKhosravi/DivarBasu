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
        REFERENCES user(user_id)
        ON DELETE CASCADE
);

CREATE TABLE product_bookmark (
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    bookmarked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, product_id),

    CONSTRAINT fk_product_bookmark_user
        FOREIGN KEY (user_id)
        REFERENCES user(user_id)
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
        REFERENCES user(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_booth_bookmark_booth
        FOREIGN KEY (booth_id)
        REFERENCES booth(booth_id)
        ON DELETE CASCADE
);

-- vip users tables:

CREATE TABLE subscription_plan (
    plan_id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    duration_days INT,
    current_price NUMERIC(12,2) NOT NULL CHECK (current_price >= 0)
);

CREATE TABLE vip_subscription (
    subscription_id SERIAL PRIMARY KEY,

    user_id INT NOT NULL,
    plan_id INT NOT NULL,

    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,

    price_at_purchase NUMERIC(12,2) NOT NULL CHECK (price_at_purchase >= 0),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_vip_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_vip_plan
        FOREIGN KEY (plan_id)
        REFERENCES subscription_plan(plan_id)
        ON UPDATE NO ACTION
        ON DELETE RESTRICT
);

-- product tables:

CREATE TABLE good (
    good_id SERIAL PRIMARY KEY,

    booth_id INT NOT NULL
        REFERENCES booth(booth_id)
        ON DELETE CASCADE,

    title VARCHAR(200) NOT NULL,

    description TEXT,

    image_url TEXT,

    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE service (
    service_id SERIAL PRIMARY KEY,

    booth_id INT NOT NULL
        REFERENCES booth(booth_id)
        ON DELETE CASCADE,

    title VARCHAR(200) NOT NULL,

    description TEXT,

    image_url TEXT,

    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),

    pricing_type VARCHAR(20)
        CHECK (pricing_type IN ('PER_HOUR','PER_PROJECT')),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE service_schedule (
    schedule_id SERIAL PRIMARY KEY,

    service_id INT NOT NULL
        REFERENCES service(service_id)
        ON DELETE CASCADE,

    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,

    is_reserved BOOLEAN DEFAULT FALSE,

    CONSTRAINT chk_service_time
        CHECK (end_time > start_time)
);

-- seller tables:

CREATE TABLE seller_request (
    request_id SERIAL PRIMARY KEY,

    user_id INT NOT NULL
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    bank_account VARCHAR(50) NOT NULL,

    payment_receipt_image TEXT,

    student_card_image TEXT,

    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('PENDING','APPROVED','REJECTED')),

    reviewed_by INT
        REFERENCES employee(employee_id),

    reviewed_at TIMESTAMP,

    rejection_reason TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE seller (
    user_id INT PRIMARY KEY
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    approved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE booth (
    booth_id SERIAL PRIMARY KEY,

    seller_id INT NOT NULL
        REFERENCES seller(user_id)
        ON DELETE CASCADE,

    name VARCHAR(150) NOT NULL,
    description TEXT,
    image_url TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
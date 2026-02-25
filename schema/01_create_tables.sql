-- ordinary user tables:

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

-- vip user tables:

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
        REFERENCES user(user_id)
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

    stock INT DEFAULT 0 CHECK (stock >= 0),

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
    schedule_id SERIAL,

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

‍CREATE TABLE seller_request (
    request_id SERIAL PRIMARY KEY,

    user_id INT NOT NULL
        REFERENCES user(user_id)
        ON DELETE RESTRICT,

    bank_account VARCHAR(50) NOT NULL,
    payment_receipt_image TEXT,
    student_card_image TEXT,

    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('PENDING','APPROVED','REJECTED')),

    reviewed_by INT
        REFERENCES support(support_id)
        ON DELETE RESTRICT,

    reviewed_at TIMESTAMP,

    rejection_reason TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE booth (
    booth_id SERIAL PRIMARY KEY,

    owner_id INT NOT NULL
        REFERENCES user(user_id)
        ON DELETE RESTRICT,

    name VARCHAR(150) NOT NULL,
    description TEXT,
    image_url TEXT,

    is_active BOOLEAN DEFAULT TRUE,
    deleted_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    status VARCHAR(20)
        DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE','SUSPENDED','DELETED'))
);

-- collaborator tables:

CREATE TABLE booth_collaboration_request (
    request_id SERIAL PRIMARY KEY,

    booth_id INT NOT NULL
        REFERENCES booth(booth_id)
        ON DELETE CASCADE,

    user_id INT NOT NULL
        REFERENCES user(user_id)
        ON DELETE CASCADE,

    message TEXT,

    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('PENDING','APPROVED','REJECTED')),

    reviewed_by INT
        REFERENCES support(support_id),

    reviewed_at TIMESTAMP,
    rejection_reason TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE booth_collaborator (
    booth_id INT
        REFERENCES booth(booth_id)
        ON DELETE CASCADE,

    user_id INT
        REFERENCES user(user_id)
        ON DELETE CASCADE,

    can_add_product BOOLEAN DEFAULT FALSE,
    can_edit_all_products BOOLEAN DEFAULT FALSE,
    can_edit_own_products BOOLEAN DEFAULT FALSE,
    can_edit_booth_info BOOLEAN DEFAULT FALSE,

    PRIMARY KEY (booth_id, user_id)
);


-- goldeb subscription tables:

CREATE TABLE golden_plan (
    plan_id SERIAL PRIMARY KEY,

    name VARCHAR(50) UNIQUE NOT NULL,

    duration_days INT NOT NULL CHECK (duration_days > 0),

    current_price NUMERIC(12,2) NOT NULL CHECK (current_price >= 0),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE golden_booth_subscription (
    subscription_id SERIAL PRIMARY KEY,

    booth_id INT NOT NULL
        REFERENCES booth(booth_id)
        ON DELETE NO ACTION,

    plan_id INT NOT NULL
        REFERENCES golden_plan(plan_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,

    price_at_purchase NUMERIC(12,2) NOT NULL CHECK (price_at_purchase >= 0),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_valid_period
        CHECK (end_date > start_date)
);

-- support tables:

CREATE TABLE support (
    support_id SERIAL PRIMARY KEY,

    full_name VARCHAR(150) NOT NULL,

    personnel_code VARCHAR(50) UNIQUE NOT NULL,

    password_hash TEXT NOT NULL,

    image_url TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- badge tables:

CREATE TABLE badge (
    badge_id SERIAL PRIMARY KEY,

    title VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE booth_badge (
    booth_id INT NOT NULL
        REFERENCES booth(booth_id)
        ON DELETE RESTRICT,

    badge_id INT NOT NULL
        REFERENCES badge(badge_id)
        ON DELETE RESTRICT,

    assigned_by INT
        REFERENCES support(support_id)
        ON DELETE SET NULL,

    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,

    PRIMARY KEY (booth_id, badge_id, start_date),

    CONSTRAINT chk_badge_time
        CHECK (end_date > start_date)
);

-- discount tables:

CREATE TABLE discount (
    discount_id SERIAL PRIMARY KEY,

    code VARCHAR(50) UNIQUE NOT NULL,

    discount_kind VARCHAR(20)
        CHECK (discount_kind IN ('PERCENT','FIXED')) NOT NULL,

    value NUMERIC(12,2) NOT NULL CHECK (value > 0),

    start_date TIMESTAMP,
    end_date TIMESTAMP,

    max_usage INT CHECK (max_usage IS NULL OR max_usage > 0),
    used_count INT DEFAULT 0 CHECK (used_count >= 0),

    is_active BOOLEAN DEFAULT TRUE,

    created_by INT
        REFERENCES support(support_id)
        ON DELETE SET NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_discount_time
        CHECK (end_date IS NULL OR end_date > start_date)
);

CREATE TABLE discount_user (
    discount_id INT
        REFERENCES discount(discount_id)
        ON DELETE CASCADE,

    user_id INT
        REFERENCES user(user_id)
        ON DELETE CASCADE,

    PRIMARY KEY (discount_id, user_id)
);

CREATE TABLE discount_booth (
    discount_id INT
        REFERENCES discount(discount_id)
        ON DELETE CASCADE,

    booth_id INT
        REFERENCES booth(booth_id)
        ON DELETE CASCADE,

    PRIMARY KEY (discount_id, booth_id)
);

-- subscription plan log tables:

CREATE TABLE subscription_plan_log (
    log_id SERIAL PRIMARY KEY,

    plan_id INT NOT NULL
        REFERENCES subscription_plan(plan_id)
        ON DELETE CASCADE,

    old_duration_days INT,
    new_duration_days INT,

    old_price NUMERIC(12,2),
    new_price NUMERIC(12,2),

    changed_by INT
        REFERENCES support(support_id)
        ON DELETE SET NULL,

    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- booth suspension tables:

CREATE TABLE booth_suspension (
    suspension_id SERIAL PRIMARY KEY,

    booth_id INT NOT NULL
        REFERENCES booth(booth_id)
        ON DELETE CASCADE,

    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,

    created_by INT
        REFERENCES support(support_id)
        ON DELETE SET NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- cart tables:

CREATE TABLE cart (
    cart_id SERIAL PRIMARY KEY,

    user_id INT UNIQUE NOT NULL
        REFERENCES user(user_id)
        ON DELETE CASCADE,

    status VARCHAR(20)
        DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE','LOCKED')),
    
    locked_until TIMESTAMP,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cart_item (
    cart_item_id SERIAL PRIMARY KEY,

    cart_id INT NOT NULL
        REFERENCES cart(cart_id)
        ON DELETE CASCADE,

    good_id INT
        REFERENCES good(good_id)
        ON DELETE CASCADE,

    schedule_id INT
        REFERENCES service_schedule(schedule_id)
        ON DELETE CASCADE,


    quantity INT DEFAULT 1 CHECK (quantity > 0),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_product_type
    CHECK (
        (
            good_id IS NOT NULL
            AND schedule_id IS NULL
        )
        OR
        (
            schedule_id IS NOT NULL
            AND good_id IS NULL
        )
    )
);

-- locked cart + order tables:

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,

    user_id INT NOT NULL
        REFERENCES user(user_id),

    total_amount NUMERIC(12,2) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_item (
    order_item_id SERIAL PRIMARY KEY,

    order_id INT NOT NULL
        REFERENCES orders(order_id)
        ON DELETE CASCADE,

    good_id INT
        REFERENCES good(good_id),

    schedule_id INT
        REFERENCES service_schedule(schedule_id),

    quantity INT NOT NULL,

    price_at_purchase NUMERIC(12,2) NOT NULL,

    CONSTRAINT chk_order_type
    CHECK (
        (
            good_id IS NOT NULL
            AND schedule_id IS NULL
        )
        OR
        (
            schedule_id IS NOT NULL
            AND good_id IS NULL
        )
    )
);

CREATE TABLE order_discount (
    order_id INT UNIQUE
        REFERENCES orders(order_id)
        ON DELETE CASCADE,

    discount_id INT
        REFERENCES discount(discount_id)
        ON DELETE SET NULL,

    applied_amount NUMERIC(12,2) NOT NULL CHECK (applied_amount >= 0)
);
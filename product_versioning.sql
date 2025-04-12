CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT DEFAULT current_user
);

CREATE TABLE IF NOT EXISTS product_versions (
    version_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    updated_by TEXT,
    version_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action TEXT NOT NULL -- 'INSERT', 'UPDATE', 'DELETE'
);

-- 3. Функция для создания версий
CREATE OR REPLACE FUNCTION log_product_change()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        INSERT INTO product_versions (product_id, name, price, updated_at, updated_by, action)
        VALUES (
            OLD.id,
            OLD.name,
            OLD.price,
            OLD.updated_at,
            OLD.updated_by,
            TG_OP
        );
    END IF;
    IF TG_OP = 'INSERT' THEN
        INSERT INTO product_versions (product_id, name, price, updated_at, updated_by, action)
        VALUES (
            NEW.id,
            NEW.name,
            NEW.price,
            NEW.updated_at,
            NEW.updated_by,
            TG_OP
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_log_product_insert ON products;
DROP TRIGGER IF EXISTS trg_log_product_update ON products;
DROP TRIGGER IF EXISTS trg_log_product_delete ON products;

CREATE TRIGGER trg_log_product_insert
AFTER INSERT ON products
FOR EACH ROW
EXECUTE FUNCTION log_product_change();

CREATE TRIGGER trg_log_product_update
AFTER UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION log_product_change();

CREATE TRIGGER trg_log_product_delete
AFTER DELETE ON products
FOR EACH ROW
EXECUTE FUNCTION log_product_change();

-- INSERT INTO products (name, price) VALUES ('Cool Widget', 19.99);
-- UPDATE products SET price = 24.99 WHERE id = 1;
-- DELETE FROM products WHERE id = 1;
-- SELECT * FROM product_versions WHERE product_id = 1;

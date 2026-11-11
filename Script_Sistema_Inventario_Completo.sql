USE Sistema_Inventario_Comedor;
GO

-- ====================================================================
-- TABLAS MAESTRAS / CATÁLOGOS
-- ====================================================================

-- 1. Catálogo de Unidades de Medida (Kg, Litros, Libras, Unidades, etc.)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UNIDAD_MEDIDA')
BEGIN
    CREATE TABLE UNIDAD_MEDIDA(
        id_unidad INT IDENTITY(1,1) PRIMARY KEY,
        nombre_unidad VARCHAR(50) NOT NULL,
        abreviatura VARCHAR(10) NOT NULL,
        estado BIT NOT NULL DEFAULT 1
    );
END
GO

-- 2. Catálogo de Bodegas (Bodega 1, Bodega 2, etc.)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BODEGA')
BEGIN
    CREATE TABLE BODEGA(
        id_bodega INT IDENTITY(1,1) PRIMARY KEY,
        nombre_bodega VARCHAR(50) NOT NULL UNIQUE,
        descripcion VARCHAR(150) NULL,
        estado BIT NOT NULL DEFAULT 1
    );
END
GO

-- 3. Catálogo de Refrigeradoras (Refri 1, Refri 2, etc.)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'REFRIGERADORA')
BEGIN
    CREATE TABLE REFRIGERADORA(
        id_refrigeradora INT IDENTITY(1,1) PRIMARY KEY,
        nombre_refrigeradora VARCHAR(50) NOT NULL UNIQUE,
        id_bodega INT NULL, -- Opcional: si la refrigeradora está ubicada físicamente dentro de una bodega
        temperatura_rango VARCHAR(30) NULL,
        estado BIT NOT NULL DEFAULT 1,
        CONSTRAINT fk_refrigeradora_bodega FOREIGN KEY (id_bodega) REFERENCES BODEGA(id_bodega)
    );
END
GO

-- 4. Catálogo de Productos
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PRODUCTO')
BEGIN
    CREATE TABLE PRODUCTO(
        id_producto INT IDENTITY(1,1) PRIMARY KEY,
        codigo_barra VARCHAR(50) NULL,
        nombre_producto VARCHAR(100) NOT NULL,
        descripcion VARCHAR(250) NULL,
        id_unidad_medida INT NOT NULL,
        stock_minimo DECIMAL(12,2) DEFAULT 0,
        estado BIT NOT NULL DEFAULT 1,
        CONSTRAINT fk_producto_unidad FOREIGN KEY (id_unidad_medida) REFERENCES UNIDAD_MEDIDA(id_unidad)
    );
END
GO

-- ====================================================================
-- TABLAS TRANSACCIONALES (MOVIMIENTOS)
-- ====================================================================

-- 5. Entrada a Bodega / Refrigeradora
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ENTRADA_BODEGA')
BEGIN
    CREATE TABLE ENTRADA_BODEGA(
        id_entrada INT IDENTITY(1,1) PRIMARY KEY,
        fecha_entrada DATETIME NOT NULL DEFAULT GETDATE(),
        id_producto INT NOT NULL,
        cantidad DECIMAL(12,2) NOT NULL CHECK (cantidad > 0),
        id_unidad_medida INT NOT NULL,
        fecha_vencimiento DATE NULL,
        id_bodega INT NULL,            -- Puede ser NULL si se guarda directamente en refrigeradora
        id_refrigeradora INT NULL,     -- Puede ser NULL si se guarda en estante seco de bodega
        numero_lote VARCHAR(50) NULL,
        observaciones VARCHAR(255) NULL,
        id_usuario INT NOT NULL,       -- Usuario que registró la entrada
        CONSTRAINT fk_entrada_producto FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto),
        CONSTRAINT fk_entrada_unidad FOREIGN KEY (id_unidad_medida) REFERENCES UNIDAD_MEDIDA(id_unidad),
        CONSTRAINT fk_entrada_bodega FOREIGN KEY (id_bodega) REFERENCES BODEGA(id_bodega),
        CONSTRAINT fk_entrada_refrigeradora FOREIGN KEY (id_refrigeradora) REFERENCES REFRIGERADORA(id_refrigeradora),
        CONSTRAINT fk_entrada_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
    );
END
GO

-- 6. Salida de Bodega / Refrigeradora
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SALIDA_BODEGA')
BEGIN
    CREATE TABLE SALIDA_BODEGA(
        id_salida INT IDENTITY(1,1) PRIMARY KEY,
        fecha_salida DATETIME NOT NULL DEFAULT GETDATE(),
        id_producto INT NOT NULL,
        cantidad DECIMAL(12,2) NOT NULL CHECK (cantidad > 0),
        id_unidad_medida INT NOT NULL,
        fecha_vencimiento DATE NULL,   -- Lote / vencimiento del que se despacha
        id_bodega INT NULL,
        id_refrigeradora INT NULL,
        uso VARCHAR(150) NOT NULL,      -- Ej: 'Preparación desayuno', 'Almuerzo comedor', 'Cena', 'Merma por daño', etc.
        observaciones VARCHAR(255) NULL,
        id_usuario INT NOT NULL,        -- Usuario que autoriza o registra la salida
        CONSTRAINT fk_salida_producto FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto),
        CONSTRAINT fk_salida_unidad FOREIGN KEY (id_unidad_medida) REFERENCES UNIDAD_MEDIDA(id_unidad),
        CONSTRAINT fk_salida_bodega FOREIGN KEY (id_bodega) REFERENCES BODEGA(id_bodega),
        CONSTRAINT fk_salida_refrigeradora FOREIGN KEY (id_refrigeradora) REFERENCES REFRIGERADORA(id_refrigeradora),
        CONSTRAINT fk_salida_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
    );
END
GO

-- ====================================================================
-- VISTAS DE CONSULTA Y GESTIÓN
-- ====================================================================

-- Vista Detallada de Entradas
CREATE OR ALTER VIEW vw_Entradas_Detalle AS
SELECT 
    e.id_entrada,
    e.fecha_entrada,
    p.nombre_producto,
    p.descripcion AS producto_descripcion,
    e.cantidad,
    u.abreviatura AS unidad_medida,
    e.fecha_vencimiento,
    ISNULL(b.nombre_bodega, 'Sin asignar') AS bodega,
    ISNULL(r.nombre_refrigeradora, 'N/A') AS refrigeradora,
    e.numero_lote,
    usr.nombre_usuario AS registrado_por,
    e.observaciones
FROM ENTRADA_BODEGA e
INNER JOIN PRODUCTO p ON e.id_producto = p.id_producto
INNER JOIN UNIDAD_MEDIDA u ON e.id_unidad_medida = u.id_unidad
INNER JOIN USUARIO usr ON e.id_usuario = usr.id_usuario
LEFT JOIN BODEGA b ON e.id_bodega = b.id_bodega
LEFT JOIN REFRIGERADORA r ON e.id_refrigeradora = r.id_refrigeradora;
GO

-- Vista Detallada de Salidas
CREATE OR ALTER VIEW vw_Salidas_Detalle AS
SELECT 
    s.id_salida,
    s.fecha_salida,
    p.nombre_producto,
    p.descripcion AS producto_descripcion,
    s.cantidad,
    u.abreviatura AS unidad_medida,
    s.fecha_vencimiento,
    ISNULL(b.nombre_bodega, 'Sin asignar') AS bodega,
    ISNULL(r.nombre_refrigeradora, 'N/A') AS refrigeradora,
    s.uso,
    usr.nombre_usuario AS despachado_por,
    s.observaciones
FROM SALIDA_BODEGA s
INNER JOIN PRODUCTO p ON s.id_producto = p.id_producto
INNER JOIN UNIDAD_MEDIDA u ON s.id_unidad_medida = u.id_unidad
INNER JOIN USUARIO usr ON s.id_usuario = usr.id_usuario
LEFT JOIN BODEGA b ON s.id_bodega = b.id_bodega
LEFT JOIN REFRIGERADORA r ON s.id_refrigeradora = r.id_refrigeradora;
GO

-- Vista de Stock Actual por Producto
CREATE OR ALTER VIEW vw_Stock_Actual AS
SELECT 
    p.id_producto,
    p.nombre_producto,
    u.abreviatura AS unidad_medida,
    ISNULL(ent.total_entradas, 0) AS total_entradas,
    ISNULL(sal.total_salidas, 0) AS total_salidas,
    (ISNULL(ent.total_entradas, 0) - ISNULL(sal.total_salidas, 0)) AS stock_actual,
    p.stock_minimo,
    CASE 
        WHEN (ISNULL(ent.total_entradas, 0) - ISNULL(sal.total_salidas, 0)) <= p.stock_minimo THEN 'Alerta: Stock Bajo'
        ELSE 'Stock Normal'
    END AS estado_stock
FROM PRODUCTO p
INNER JOIN UNIDAD_MEDIDA u ON p.id_unidad_medida = u.id_unidad
LEFT JOIN (
    SELECT id_producto, SUM(cantidad) AS total_entradas
    FROM ENTRADA_BODEGA
    GROUP BY id_producto
) ent ON p.id_producto = ent.id_producto
LEFT JOIN (
    SELECT id_producto, SUM(cantidad) AS total_salidas
    FROM SALIDA_BODEGA
    GROUP BY id_producto
) sal ON p.id_producto = sal.id_producto
WHERE p.estado = 1;
GO

-- Vista de Alerta de Vencimiento de Productos
CREATE OR ALTER VIEW vw_Alertas_Vencimiento AS
SELECT 
    p.nombre_producto,
    e.fecha_vencimiento,
    DATEDIFF(day, GETDATE(), e.fecha_vencimiento) AS dias_para_vencer,
    e.cantidad,
    u.abreviatura AS unidad_medida,
    ISNULL(b.nombre_bodega, 'N/A') AS bodega,
    ISNULL(r.nombre_refrigeradora, 'N/A') AS refrigeradora,
    CASE 
        WHEN e.fecha_vencimiento < CAST(GETDATE() AS DATE) THEN '¡VENCIDO!'
        WHEN DATEDIFF(day, GETDATE(), e.fecha_vencimiento) <= 7 THEN 'Vence en menos de 7 días'
        WHEN DATEDIFF(day, GETDATE(), e.fecha_vencimiento) <= 30 THEN 'Vence en el mes'
        ELSE 'Vigente'
    END AS estado_vencimiento
FROM ENTRADA_BODEGA e
INNER JOIN PRODUCTO p ON e.id_producto = p.id_producto
INNER JOIN UNIDAD_MEDIDA u ON e.id_unidad_medida = u.id_unidad
LEFT JOIN BODEGA b ON e.id_bodega = b.id_bodega
LEFT JOIN REFRIGERADORA r ON e.id_refrigeradora = r.id_refrigeradora
WHERE e.fecha_vencimiento IS NOT NULL;
GO

-- ====================================================================
-- DATOS SEMILLA / INICIALES DE EJEMPLO
-- ====================================================================

-- Insertar Unidades de Medida Comunes
IF NOT EXISTS (SELECT 1 FROM UNIDAD_MEDIDA)
BEGIN
    INSERT INTO UNIDAD_MEDIDA (nombre_unidad, abreviatura) VALUES 
    ('Kilogramo', 'Kg'),
    ('Gramo', 'g'),
    ('Litro', 'L'),
    ('Mililitro', 'ml'),
    ('Libra', 'lb'),
    ('Unidad', 'und'),
    ('Caja', 'cj'),
    ('Bolsa', 'bls');
END
GO

-- Insertar Bodegas
IF NOT EXISTS (SELECT 1 FROM BODEGA)
BEGIN
    INSERT INTO BODEGA (nombre_bodega, descripcion) VALUES 
    ('Bodega 1', 'Bodega principal de secos y abarrotes'),
    ('Bodega 2', 'Bodega secundaria / insumos de limpieza'),
    ('Bodega 3', 'Bodega de reserva');
END
GO

-- Insertar Refrigeradoras
IF NOT EXISTS (SELECT 1 FROM REFRIGERADORA)
BEGIN
    INSERT INTO REFRIGERADORA (nombre_refrigeradora, id_bodega, temperatura_rango) VALUES 
    ('Refri 1', 1, '4°C a 8°C (Lácteos y verduras)'),
    ('Refri 2', 1, '-18°C (Congelador carnes)'),
    ('Refri 3', 1, '2°C a 5°C (Bebidas y perecederos)');
END
GO

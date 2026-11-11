Create database Sistema_Inventario_Comedor
	go
	use Sistema_Inventario_Comedor
	go

	CREATE TABLE ROL(
	 id_rol INT IDENTITY (1,1)PRIMARY KEY,
	 nombre_rol varchar (30) NOT NULL
	);

	INSERT INTO ROL VALUES('Administrador');

	CREATE TABLE USUARIO(
	id_usuario  INT IDENTITY (1,1)PRIMARY KEY,
	nombre_usuario varchar(30) NOT NULL,
	clave varchar(150) NOT NULL,
	id_rol INT NOT NULL,
	CONSTRAINT fk_Usuario_rol FOREIGN KEY (id_rol) REFERENCES ROL(id_rol)
	);

	INSERT INTO USUARIO VALUES ('Admin_Comedor','$2a$12$iRT/GWkMMaSLuyY15okaP.kp.0gSYSJS87k1lDkqMNhnpyIVmJTYy',1);

	
	

	create View vw_Login 
as
SELECT        dbo.Usuario.clave, dbo.Usuario.nombre_usuario, dbo.ROL.nombre_rol, dbo.ROL.id_rol
FROM            dbo.Usuario INNER JOIN
                         dbo.ROL ON dbo.Usuario.id_rol = dbo.ROL.id_rol


SELECT * FROM vw_Login;
	





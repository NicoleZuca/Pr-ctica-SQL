--Creación de la base de datos
create database Empresa_XXXX

use Empresa_XXXX

--Creación de la tabla del login, se asigna el nombre de la tabla, las columnas y los tipos de datos
create table InicioSesión
(
	Usuario varchar(20) not null,
	Clave varchar(50) not null,
	Llave varchar(100) not null
)

--creación del procedimiento almacenado de inserción de registros en la tabla del login 
go 
create proc insertar_inicioSesion
@Usuario varchar(20),
@Clave varchar(50),
@Llave varchar(100)
as 
BEGIN
SET @Clave = (ENCRYPTBYPASSPHRASE(@Llave, @Clave)); --Indicamos que la contraseña sea encriptada por medio de una llave 
insert into InicioSesión 
values(@Usuario, @Clave, @Llave)
END

--Agregar los datos a la tabla
execute insertar_inicioSesion
@Usuario = PabloHZ,
@Clave = ZPÑ102PM,
@Llave = 123

select * from InicioSesión

--Creación de las tabla Departamento
create table Departamento
(
	IdDpt int identity(1,1) not null primary key, --Se asignan las variables con sus respectivos tipos de datos, se indica la llave primaria de la tabla
	Nombre varchar(20) not null					  --acompañada por un identity para que el ID sea autoincremental de 1 en 1
);

--Creación de las tabla Empleados
create table Empleados
(
	IdEmp int identity(1,1) not null primary key,	--Se asignan las variables con sus respectivos tipos de datos, se indica la llave primaria de la tabla
	Nombre varchar(20) not null,					--acompañada por un identity para que el ID sea autoincremental de 1 en 1
	Apellido1 varchar(20) not null,
	Apellido2 varchar(20) not null,
	Departamento int not null,
	Cedula int not null,
	Telefono bigint not null

	CONSTRAINT FK_Empleados_Departamento						--Se indica la relación con la tabla departamento por medio de una llave foránea
	Foreign key (Departamento) references Departamento(IdDpt)
);

--Creación de las tabla FormSolicVacaciones (Formulario de Solicitud de vacaciones)
create table FormSolicVacaciones
(
	IdForm int identity(1,1) not null primary key,	--Se asignan las variables con sus respectivos tipos de datos, se indica la llave primaria de la tabla
	IdEmp int not null,								--acompañada por un identity para que el ID sea autoincremental de 1 en 1
	NombreEncargado varchar(100) not null,
	FechaSolicitada date not null,
	DiasTotales int not null,
	Descripcion varchar(100)

	CONSTRAINT FK_FormSolicVacaciones_Empleados		--Se indica la relación con la tabla Empleados por medio de una llave foránea
	Foreign key(IdEmp) references Empleados(IdEmp)
)

--Creación de las tabla SolicitudVac (Solicitud de Vacaciones) 
create table SolicitudVac
(
	IdSolic int identity(1,1) not null primary key,	--Se asignan las variables con sus respectivos tipos de datos, se indica la llave primaria de la tabla
	IdForm int not null,							--acompañada por un identity para que el ID sea autoincremental de 1 en 1
	Estado varchar(20) not null,
	Motivo varchar(50),
	DiasDisfrutados int 

	CONSTRAINT FK_SolicitudVac_FormSolicVacaciones	--Se indica la relación con la tabla FormSolicVacaciones por medio de una llave foránea
	Foreign key (IdForm) references FormSolicVacaciones(IdForm)
)

--Se crean los procedimientos de registro de datos en las tablas creadas anteriormente
go 
create proc insertar_departamento
@Nombre varchar(20)
as
insert into Departamento(Nombre)
values(@Nombre)

go 
create proc insertar_empleado
@Nombre varchar(20),
@Apellido1 varchar(20),
@Apellido2 varchar(20),
@Departamento varchar(20),
@Cedula int,
@Telefono bigint
as
insert into Empleados(Nombre, Apellido1, Apellido2, Departamento, Cedula, Telefono)
values(@Nombre, @Apellido1, @Apellido2, @Departamento, @Cedula, @Telefono)

go 
create proc insertar_FormSolicVacaciones
@IdEmp int,
@NombreEncargado varchar(100),
@FechaSolicitada date,
@DiasTotales int =12,
@Descripcion varchar(100)
as
insert into FormSolicVacaciones(IdEmp, NombreEncargado, FechaSolicitada, DiasTotales, Descripcion)
values(@IdEmp, @NombreEncargado, @FechaSolicitada, @DiasTotales, @Descripcion)

--Agregamos una solicitud de vacaciones en la cual, si es denegada actualizamos el motivo y ponemos los días aprobados en 0, y si es aprobada
--restamos los días aprobados del total de días de vacaciones que tiene el empleado
go 
create proc insertar_SolicitudVac
@IdForm int,
@Estado varchar(20),
@Motivo varchar(50),
@DiasDisfrutados int 
as
insert into SolicitudVac(IdForm, Estado, Motivo, DiasDisfrutados)
values(@IdForm, @Estado, @Motivo, @DiasDisfrutados)
declare @DiasVacaciones int
select @DiasVacaciones = FormSolicVacaciones.DiasTotales  
from Empleados inner join FormSolicVacaciones on Empleados.IdEmp = Empleados.IdEmp 
where Empleados.IdEmp = Empleados.IdEmp

if(@Estado = 'Denegado')
begin 
update SolicitudVac set DiasDisfrutados = 0, Motivo = @Motivo where IdForm = @IdForm
end
else if (@Estado = 'Aprobado')
begin
update FormSolicVacaciones set DiasTotales = DiasTotales-@DiasVacaciones where IdForm = @IdForm
update SolicitudVac set DiasDisfrutados = @DiasDisfrutados where IdForm = @IdForm
end

--Se ejecutan los procedimientos almacenados que se crearon anteriormente
execute insertar_departamento
@Nombre = Administrativo

execute insertar_empleado
@Nombre = Paula,
@Apellido1 = Méndez,
@Apellido2 = Rodríguez,
@Departamento = 5,
@Cedula = 401980372,
@Telefono = 89817294

execute insertar_FormSolicVacaciones
@IdEmp = 1,
@NombreEncargado = 'Ana Vargas',
@FechaSolicitada = '2022-05-03',
@Descripcion = 'Cita médica'

execute insertar_SolicitudVac
@IdForm = 11,
@Estado = Aprobado,
@Motivo = null,
@DiasDisfrutados = 1

--Los diferentes select para verificar la información de cada tabla
select * from Departamento
select * from Empleados
select * from FormSolicVacaciones
select * from SolicitudVac

--Intentar sumar los días aprobados de vacaciones por ID de empleado y retornar la cantidad
alter proc ObtenerDiasDisfrutados
(
	@IdEmp int
)
as
begin
	select distinct e.IdEmp, SUM(sv.DiasDisfrutados) as DíasDisfrutado
	from FormSolicVacaciones fs 
	inner join SolicitudVac sv on fs.IdForm = sv.IdForm 
	inner join Empleados e on e.IdEmp = fs.IdEmp
	where fs.IdEmp = @IdEmp group by e.IdEmp, DiasDisfrutados
end

execute ObtenerDiasDisfrutados 2


--Creación del procedimiento para buscar registros en la tabla de empleados por medio de filtros de búsqueda
create proc filtrosEmp
@Dato varchar(20) 
as
select IdEmp, Nombre, Apellido1, Apellido2, Departamento, Cedula, Telefono
from Empleados where Nombre like @Dato or Apellido1 like @Dato or Apellido2 like @Dato or Departamento like @Dato or Cedula like @Dato or Telefono like @Dato + '%'

--Select para realizar la búsqueda filtrada de elementos de la tabla empleados
DECLARE	@return_value int
EXEC	@return_value = filtrosEmp
		@Dato = N'1'
SELECT	'Return Value' = @return_value
GO


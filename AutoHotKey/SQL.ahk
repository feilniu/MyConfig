; SQL auto-input
; Last Change: 2016-02-18 12:52:27

:?:;s::SELECT
:?:;tp::TOP(10)
:?:;d::DISTINCT
:?:;f::FROM
:?:;lmt::LIMIT
:?:;ij::INNER JOIN
:?:;lj::LEFT JOIN
:?:;rj::RIGHT JOIN
:?:;fj::FULL JOIN
:?:;cj::CROSS JOIN
:?:;ca::CROSS APPLY
:?:;oa::OUTER APPLY
:?:;w::WHERE
:?:;h::HAVING
:?:;ad::AND
:?:;sd::SELECT DISTINCT
:?:;st::SELECT TOP(10) *
:?:;stf::SELECT TOP(10) * FROM
:?:;sf::SELECT * FROM
:?:;sft::SELECT * FROM sys.tables
:?:;sfi::SELECT * FROM sys.indexes
:?:;sfv::SELECT * FROM sys.views
:?:;sfp::SELECT * FROM sys.procedures
:?:;sfo::SELECT * FROM sys.objects WHERE type IN ('P','FN','SN','TR','IF','TF','U','V')
:?:;sfc::SELECT table_name=object_name(object_id),* FROM sys.columns WHERE name
:?:;sfe::SELECT * FROM sys.extended_properties
:?:;cdt::
    SendInput create_date > '%A_YYYY%%A_MM%%A_DD%'
return
:?:;mdt::
    SendInput modify_date > '%A_YYYY%%A_MM%%A_DD%'
return
:?:;gb::GROUP BY
:?:;ob::ORDER BY
:?:;pb::PARTITION BY
:?:;ba::BETWEEN AND {left 5}
:?:;wi::WITH
:?:;clt::COLLATE

:?:;its::INTERSECT
:?:;exc::EXCEPT
:?:;uni::UNION
:?:;una::UNION ALL

:?:;ins::INSERT
:?:;ii::INSERT INTO
:?:;val::VALUES
:?:;upd::UPDATE
:?:;del::DELETE
:?:;delf::DELETE FROM
:?:;mg::MERGE
:?:;us::USING

:?:;ci::CREATE INDEX
:?:;cui::CREATE UNIQUE INDEX
:?:;cci::CREATE CLUSTERED INDEX
:?:;cuci::CREATE UNIQUE CLUSTERED INDEX

:?:;to::INTO
:?:;dc::DECLARE
:?:;ct::CREATE TABLE
:?:;at::ALTER TABLE
:?:;dt::DROP TABLE
:?:;tt::TRUNCATE TABLE
:?:;ai::AUTO_INCREMENT
:?:;id::IDENTITY(1,1)
:?:;uqid::uniqueidentifier
:?:;cstr::CONSTRAINT
:?:;pk::PRIMARY KEY
:?:;pkc::PRIMARY KEY CLUSTERED
:?:;uq::UNIQUE
:?:;fk::FOREIGN KEY
:?:;ref::REFERENCES
:?:;def::DEFAULT
:?:;ck::CHECK
:?:;n::NULL
:?:;nn::NOT NULL

:?:;cf::CREATE FUNCTION
:?:;cp::CREATE PROCEDURE
:?:;cv::CREATE VIEW
:?:;ctr::CREATE TRIGGER
:?:;csc::CREATE SCHEMA
:?:;csy::CREATE SYNONYM

:?:;b::BEGIN
:?:;e::END
:?:;cs::CASE
:?:;wn::WHEN
:?:;tn::THEN
:?:;el::ELSE
:?:;wl::WHILE
:?:;rt::RETURN
:?:;rts::RETURNS
:?:;bt::BEGIN TRY
:?:;et::END TRY
:?:;bc::BEGIN CATCH
:?:;ec::END CATCH

:?:;l::LIKE
:?:;nl::NOT LIKE
:?:;esc::ESCAPE '\'
:?:;es::EXISTS
:?:;nes::NOT EXISTS

:?:;btr::BEGIN TRANSACTION
:?:;cmt::COMMIT TRANSACTION
:?:;rbk::ROLLBACK TRANSACTION

:?:;cnt::COUNT
:?:;nif::NULLIF
:?:;isn::ISNULL
:?:;cls::COALESCE
:?:;cvt::CONVERT
:?:;chi::CHARINDEX
:?:;pai::PATINDEX
:?:;rep::REPLACE
:?:;rct::REPLICATE
:?:;sub::SUBSTRING
:?:;stu::STUFF
:?:;rev::REVERSE
:?:;dd::DATEDIFF
:?:;da::DATEADD
:?:;dp::DATEPART
:?:;dl::DATALENGTH
:?:;cks::CHECKSUM
:?:;bcks::BINARY_CHECKSUM
:?:;hsb::HASHBYTES
:?:;rn::ROW_NUMBER() OVER
:?:;rk::RANK() OVER
:?:;drk::DENSE_RANK() OVER
:?:;bth::sys.fn_varbintohexstr
:?:;oid::OBJECT_ID
:?:;onm::OBJECT_NAME
:?:;sid::SCHEMA_ID
:?:;snm::SCHEMA_NAME

:?*:;gd::GETDATE()
:?*:;rdm::ABS(CHECKSUM(NEWID()))
:?*:;scpid::SCOPE_IDENTITY()
:?*:;nlk::WITH (NOLOCK)
:?*:;idk::WITH (IGNORE_DUP_KEY = ON)
:?*:;fxp::FOR XML PATH('')
:?*:;rserr::RAISERROR('',16,1){left 7}

:?:;snc::SET NOCOUNT ON
:?:;sii::SET IDENTITY_INSERT
:?:;sxa::SET XACT_ABORT ON
:?:;sru::SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
:?:;src::SET TRANSACTION ISOLATION LEVEL READ COMMITTED
:?:;srr::SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
:?:;ssl::SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
:?*:;mp::'1[34578]'{+}REPLICATE('[0-9]',9)
:?*:;23::23:59:59

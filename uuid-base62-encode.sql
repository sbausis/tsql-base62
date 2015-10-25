USE [testdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--##############################################################################

IF EXISTS (SELECT *
	FROM   sys.objects
	WHERE  object_id = OBJECT_ID(N'[dbo].[fn_hex2bin]')
	AND type IN ( N'FN' ))
	DROP FUNCTION [dbo].[fn_hex2bin]

GO

CREATE FUNCTION [dbo].[fn_hex2bin](@hexstring [varchar](max))
RETURNS [varbinary](max) WITH EXECUTE AS CALLER
AS
BEGIN
	declare @hexbin varbinary(max);
	set @hexbin = CONVERT(varbinary(max), @hexstring, 2);
	return @hexbin;
END

GO

--##############################################################################

IF EXISTS (SELECT *
	FROM   sys.objects
	WHERE  object_id = OBJECT_ID(N'[dbo].[fn_bin2hex]')
	AND type IN ( N'FN' ))
	DROP FUNCTION [dbo].[fn_bin2hex]

GO

CREATE FUNCTION [dbo].[fn_bin2hex](@hexbin [varbinary](max))
RETURNS [varchar](max) WITH EXECUTE AS CALLER
AS
BEGIN
	declare @hexstring varchar(max);
	set @hexstring = CONVERT(varchar(max), @hexbin, 2);
	return @hexstring;
END

GO

--##############################################################################

IF EXISTS (SELECT *
	FROM   sys.objects
	WHERE  object_id = OBJECT_ID(N'[dbo].[fn_uuid2hex]')
	AND type IN ( N'FN' ))
	DROP FUNCTION [dbo].[fn_uuid2hex]

GO

CREATE FUNCTION [dbo].[fn_uuid2hex](@uuid_string [varchar](36))
RETURNS [varchar](32) WITH EXECUTE AS CALLER
AS
BEGIN
	declare @uuid_hex varchar(32);
	set @uuid_hex = SUBSTRING(@uuid_string, 35, 2) + SUBSTRING(@uuid_string, 33, 2) + SUBSTRING(@uuid_string, 31, 2) + SUBSTRING(@uuid_string, 29, 2) + SUBSTRING(@uuid_string, 27, 2) + SUBSTRING(@uuid_string, 25, 2) + SUBSTRING(@uuid_string, 22, 2) + SUBSTRING(@uuid_string, 20, 2) + SUBSTRING(@uuid_string, 15, 4) + SUBSTRING(@uuid_string, 10, 4) + SUBSTRING(@uuid_string, 1, 8);
	return @uuid_hex;
END

GO

--##############################################################################

IF EXISTS (SELECT *
	FROM   sys.objects
	WHERE  object_id = OBJECT_ID(N'[dbo].[fn_hex2uuid]')
	AND type IN ( N'FN' ))
	DROP FUNCTION [dbo].[fn_hex2uuid]

GO

CREATE FUNCTION [dbo].[fn_hex2uuid](@uuid_hex [varchar](32))
RETURNS [varchar](36) WITH EXECUTE AS CALLER
AS
BEGIN
	declare @uuid_string varchar(36);
	set @uuid_string = SUBSTRING(@uuid_hex, 25, 8) + '-' + SUBSTRING(@uuid_hex, 21, 4) + '-' + SUBSTRING(@uuid_hex, 17, 4) + '-' + SUBSTRING(@uuid_hex, 15, 2) + SUBSTRING(@uuid_hex, 13, 2) + '-' + SUBSTRING(@uuid_hex, 11, 2) + SUBSTRING(@uuid_hex, 9, 2) + SUBSTRING(@uuid_hex, 7, 2) + SUBSTRING(@uuid_hex, 5, 2) + SUBSTRING(@uuid_hex, 3, 2) + SUBSTRING(@uuid_hex, 1, 2);
	return @uuid_string;
END

GO

--##############################################################################

IF EXISTS (SELECT *
	FROM   sys.objects
	WHERE  object_id = OBJECT_ID(N'[dbo].[fn_base62encode]')
	AND type IN ( N'FN' ))
	DROP FUNCTION [dbo].[fn_base62encode]

GO

CREATE FUNCTION [dbo].[fn_base62encode](@hexbin [varbinary](max))
RETURNS [varchar](max) WITH EXECUTE AS CALLER
AS
BEGIN
	declare @c_base62_digits char(62) =   '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
	
	declare @base62_string varchar(max) = '';
	set @hexbin = CONVERT(varbinary(max), REVERSE(@hexbin));
	declare @srcLen int = DATALENGTH(@hexbin);
	declare @v_iterator int = 0;
	declare @dstLen int = 0;
	declare @bCarry tinyint = 0;
	declare @dstDigit bigint = 0;
	WHILE ( @bCarry = 0 )
	BEGIN
		set @v_iterator = @srcLen;
		set @bCarry = 1;
		set @dstDigit = 0;
		WHILE ( @v_iterator > 0 )
		BEGIN
			declare @srcDigit bigint = convert(bigint, SUBSTRING(@hexbin, @v_iterator, 1));
			set @dstDigit = (@dstDigit * 256 + @srcDigit);
			IF @dstDigit >= 62
			BEGIN
			 	set @hexbin = CONVERT(varbinary(max), STUFF(@hexbin, @v_iterator, 1, CONVERT(varbinary(1),(@dstDigit/62))));
				set @dstDigit %= 62;
				set @bCarry = 0;
			END
			ELSE
				set @hexbin = CONVERT(varbinary(max), STUFF(@hexbin, @v_iterator, 1, 0x00));

			set @v_iterator = @v_iterator - 1;
		END
		set @base62_string = @base62_string + substring( @c_base62_digits, @dstDigit + 1, 1 );
		set @dstLen = @dstLen + 1;
	END
	set @base62_string = REVERSE(@base62_string);
	return @base62_string;
END

GO

--##############################################################################

IF EXISTS (SELECT *
	FROM   sys.objects
	WHERE  object_id = OBJECT_ID(N'[dbo].[fn_base62decode]')
	AND type IN ( N'FN' ))
	DROP FUNCTION [dbo].[fn_base62decode]

GO

CREATE FUNCTION [dbo].[fn_base62decode](@base62_str [varchar](max))
RETURNS [varbinary](max) WITH EXECUTE AS CALLER
AS
BEGIN
	declare @c_base62_digits char(62) =   '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
	declare @c_base62_bin varbinary(75) = 0x000102030405060708097F7F7F7F7F7F7F0A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122237F7F7F7F7F7F2425262728292A2B2C2D2E2F303132333435363738393A3B3C3D;

	declare @base62_bin varchar(max) = '';
	--declare @base62_bin varbinary(max);
	declare @srcLen int = DATALENGTH(@base62_str);
	declare @v_iterator int = 0;
	declare @dstLen int = 0;
	declare @bCarry tinyint = 0;
	declare @dstDigit bigint = 0;
	WHILE ( @bCarry = 0 )
	BEGIN
		set @v_iterator = 0;
		set @bCarry = 1;
		set @dstDigit = 0;
		WHILE ( @v_iterator < @srcLen )
		BEGIN
			declare @mapPos tinyint = convert(tinyint, convert(varbinary(1), SUBSTRING(@base62_str, @v_iterator+1, 1))) - 0x30;
			declare @srcDigit bigint = convert(bigint, SUBSTRING(@c_base62_bin, @mapPos+1, 1));
			set @dstDigit = (@dstDigit * 62 + @srcDigit);
			IF @dstDigit >= 256
			BEGIN
			 	set @base62_str = STUFF(@base62_str, @v_iterator+1, 1, substring( @c_base62_digits, @dstDigit/256+1, 1 ));
				set @dstDigit %= 256;
				set @bCarry = 0;
			END
			ELSE
				set @base62_str = STUFF(@base62_str, @v_iterator+1, 1, 0x30);
			set @v_iterator = @v_iterator + 1;
		END
		set @base62_bin = @base62_bin + CONVERT(varchar(1), CONVERT(varbinary(1), @dstDigit));
		--set @base62_bin = CONVERT(varbinary(max), CONCAT(@base62_bin, CONVERT(varbinary(1), @dstDigit)));
		set @dstLen = @dstLen + 1;
	END
	--set @base62_bin = CONVERT(varbinary(max), REVERSE(@base62_bin));
	--return @base62_bin;
	declare @return_bin varbinary(max) = CONVERT(varbinary(max), REVERSE(@base62_bin));
	return @return_bin;
END

GO

--##############################################################################

IF EXISTS (SELECT *
	FROM   sys.objects
	WHERE  object_id = OBJECT_ID(N'[dbo].[fn_uuid_to_base62]')
	AND type IN ( N'FN' ))
	DROP FUNCTION [dbo].[fn_uuid_to_base62]

GO

CREATE FUNCTION [dbo].[fn_uuid_to_base62](@uuid [varchar](max))
RETURNS [varchar](max) WITH EXECUTE AS CALLER
AS
BEGIN
	declare @base62_string varchar(max) = dbo.fn_base62encode(dbo.fn_hex2bin(dbo.fn_uuid2hex(@uuid)));
	return @base62_string;
END

GO

--##############################################################################

IF EXISTS (SELECT *
	FROM   sys.objects
	WHERE  object_id = OBJECT_ID(N'[dbo].[fn_base62_to_uuid]')
	AND type IN ( N'FN' ))
	DROP FUNCTION [dbo].[fn_base62_to_uuid]

GO

CREATE FUNCTION [dbo].[fn_base62_to_uuid](@base [varchar](max))
RETURNS [varchar](max) WITH EXECUTE AS CALLER
AS
BEGIN
	declare @hex_string varchar(max) = dbo.fn_hex2uuid(dbo.fn_bin2hex(dbo.fn_base62decode(@base)));
	return @hex_string;
END

GO

--##############################################################################

select dbo.fn_hex2bin('A1B9'), 0xA1B9;
select dbo.fn_bin2hex(0xA1B9), 'A1B9';

select dbo.fn_hex2bin('93627C68D74D5BA145E40AC0BE778A5C'), 0x93627C68D74D5BA145E40AC0BE778A5C;
select dbo.fn_bin2hex(0x93627C68D74D5BA145E40AC0BE778A5C), '93627C68D74D5BA145E40AC0BE778A5C';

GO

--##############################################################################

select dbo.fn_uuid2hex('BE778A5C-0AC0-45E4-A15B-4DD7687C6293'), '93627C68D74D5BA145E40AC0BE778A5C';
select dbo.fn_hex2uuid('93627C68D74D5BA145E40AC0BE778A5C'), 'BE778A5C-0AC0-45E4-A15B-4DD7687C6293';

GO

--##############################################################################

select dbo.fn_base62encode(0x93627C68D74D5BA145E40AC0BE778A5C), 0x93627C68D74D5BA145E40AC0BE778A5C;
select dbo.fn_base62encode(dbo.fn_hex2bin(dbo.fn_uuid2hex('BE778A5C-0AC0-45E4-A15B-4DD7687C6293'))), 0x93627C68D74D5BA145E40AC0BE778A5C;

GO

--##############################################################################

select dbo.fn_base62decode('4U6sZo9kFS2weMLGMzWbTo'), 'BE778A5C-0AC0-45E4-A15B-4DD7687C6293';
select dbo.fn_hex2uuid(dbo.fn_bin2hex(dbo.fn_base62decode('4U6sZo9kFS2weMLGMzWbTo'))), 'BE778A5C-0AC0-45E4-A15B-4DD7687C6293';

GO

--##############################################################################

select dbo.fn_base62_to_uuid('4U6sZo9kFS2weMLGMzWbTo'), 'BE778A5C-0AC0-45E4-A15B-4DD7687C6293';
select dbo.fn_uuid_to_base62('BE778A5C-0AC0-45E4-A15B-4DD7687C6293'), '4U6sZo9kFS2weMLGMzWbTo';

GO

--##############################################################################

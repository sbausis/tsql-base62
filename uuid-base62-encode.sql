
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--##############################################################################
-- remove old Functions

IF EXISTS (SELECT *
	FROM   sys.objects
	WHERE  object_id = OBJECT_ID(N'[dbo].[fn_hex2bin]')
	AND type IN ( N'FN' ))
	DROP FUNCTION [dbo].[fn_hex2bin]

IF EXISTS (SELECT *
	FROM   sys.objects
	WHERE  object_id = OBJECT_ID(N'[dbo].[fn_bin2hex]')
	AND type IN ( N'FN' ))
	DROP FUNCTION [dbo].[fn_bin2hex]

GO

--##############################################################################

IF EXISTS (SELECT *
	FROM   sys.objects
	WHERE  object_id = OBJECT_ID(N'[dbo].[fn_uuid2hex]')
	AND type IN ( N'FN' ))
	DROP FUNCTION [dbo].[fn_uuid2hex]

GO

CREATE FUNCTION [dbo].[fn_uuid2hex](@uuid_string [varchar](36))
RETURNS [varbinary](16) WITH EXECUTE AS CALLER
AS
BEGIN
	declare @uuid_hex varchar(32);
	set @uuid_hex = SUBSTRING(@uuid_string, 35, 2) + SUBSTRING(@uuid_string, 33, 2) + SUBSTRING(@uuid_string, 31, 2) + SUBSTRING(@uuid_string, 29, 2) + SUBSTRING(@uuid_string, 27, 2) + SUBSTRING(@uuid_string, 25, 2) + SUBSTRING(@uuid_string, 22, 2) + SUBSTRING(@uuid_string, 20, 2) + SUBSTRING(@uuid_string, 15, 4) + SUBSTRING(@uuid_string, 10, 4) + SUBSTRING(@uuid_string, 1, 8);
	return CONVERT(varbinary(16), @uuid_hex, 2);
END

GO

--##############################################################################

IF EXISTS (SELECT *
	FROM   sys.objects
	WHERE  object_id = OBJECT_ID(N'[dbo].[fn_hex2uuid]')
	AND type IN ( N'FN' ))
	DROP FUNCTION [dbo].[fn_hex2uuid]

GO

CREATE FUNCTION [dbo].[fn_hex2uuid](@hexbin [varbinary](16))
RETURNS [varchar](36) WITH EXECUTE AS CALLER
AS
BEGIN
	declare @uuid_hex varchar(32) = CONVERT(varchar(32), @hexbin, 2);
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

CREATE FUNCTION [dbo].[fn_base62encode](@binary_data [varbinary](max))
RETURNS [varchar](max) WITH EXECUTE AS CALLER
AS
BEGIN
	
	declare @c_base62_digits char(62) =   '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

	--declare @binary_data varbinary(max) = 0x61626364;
	declare @string_data varchar(max) = CONVERT(varchar(max), @binary_data);

	--print N'Charset:' + RTRIM(CAST(@c_base62_digits AS nvarchar(max)));
	--print N'Input-Binary:';
	--print @binary_data;
	--print N'Input-String:' + @string_data;

	declare @base62_string varchar(max) = '';
	declare @base62_len int = 0;
	declare @carry_flag bit = 'TRUE';
	WHILE ( @carry_flag = 'TRUE' )
	BEGIN
		set @carry_flag = 'FALSE';
		declare @dstDigit bigint = 0;
		declare @string_len int = DATALENGTH(@string_data);

		--print N'Len:' + RTRIM(CAST(@string_len AS nvarchar(max)));

		declare @interator int = 1;
		WHILE ( @interator <= @string_len )
		BEGIN
			declare @byte_data varchar(1) = SUBSTRING(@string_data, @interator, 1);
			set @dstDigit = (@dstDigit * 256 + CONVERT(tinyint, CONVERT(varbinary(1), @byte_data)));

			--print N'Index:' + RTRIM(CAST(@interator AS nvarchar(max)));
			--print CONVERT(varbinary(max), @byte_data);

			IF @dstDigit >= 62
			BEGIN
				set @string_data = STUFF(@string_data, @interator, 1, CONVERT(varchar(1), CONVERT(varbinary(1), (@dstDigit/62))));
				set @dstDigit %= 62;
				set @carry_flag = 'TRUE';
			END
			ELSE
			BEGIN
				IF @interator = 1
				BEGIN
					set @string_data = STUFF(@string_data, @interator, 1, '');
					set @string_len = @string_len - 1;
					set @interator = @interator - 1;
				END
				ELSE
				BEGIN
					set @string_data = STUFF(@string_data, @interator, 1, 0x00);
				END
			END

			set @interator = @interator + 1;
		END

		set @base62_string = substring( @c_base62_digits, @dstDigit + 1, 1 ) + @base62_string;
		set @base62_len = @base62_len + 1;

		--print N'base62_string[' + RTRIM(CAST(@base62_len AS nvarchar(max))) + ']:' + @base62_string;

	END

	--print N'Result[' + RTRIM(CAST(@base62_len AS nvarchar(max))) + ']:' + @base62_string;

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

CREATE FUNCTION [dbo].[fn_base62decode](@string_data [varchar](max))
RETURNS [varbinary](max) WITH EXECUTE AS CALLER
AS
BEGIN
	--declare @string_data varchar(max) = '4U6sZo9kFS2weMLGMzWbTo';

	declare @c_base62_digits char(62) =   '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
	declare @c_base62_bin varbinary(75) = 0x000102030405060708097F7F7F7F7F7F7F0A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122237F7F7F7F7F7F2425262728292A2B2C2D2E2F303132333435363738393A3B3C3D;

	declare @string_bin varbinary(max) = CAST(@string_data AS varbinary(max));
	declare @base62_bin varbinary(max);

	--print N'Charset:' + RTRIM(CAST(@c_base62_digits AS nvarchar(max)));
	--print N'Input-Binary:';
	--print @string_bin;
	--print N'Input-String:' + @string_data;

	declare @dstLen int = 0;
	declare @carry_flag bit = 'TRUE';
	WHILE ( @carry_flag = 'TRUE' )
	BEGIN
		set @carry_flag = 'FALSE';
		declare @dstDigit bigint = 0;
		declare @string_len int = DATALENGTH(@string_bin);

		--print N'Len:' + RTRIM(CAST(@string_len AS nvarchar(max)));

		declare @iterator int = 1;
		WHILE ( @iterator <= @string_len )
		BEGIN
			declare @mapPos tinyint = CAST(SUBSTRING(@string_bin, @iterator, 1) AS tinyint) - 0x2F;
			declare @srcDigit tinyint = CAST(SUBSTRING(@c_base62_bin, @mapPos, 1) AS tinyint);
			set @dstDigit = (@dstDigit * 62 + @srcDigit);

			--print N'Index:' + RTRIM(CAST(@iterator AS nvarchar(max)));
			--print CONVERT(varbinary(max), @mapPos);
			--print CONVERT(varbinary(max), @srcDigit);
			--print CONVERT(varbinary(max), @dstDigit);

			IF @dstDigit >= 256
			BEGIN
			 	set @string_bin = CAST(STUFF(@string_bin, @iterator, 1, substring( @c_base62_digits, @dstDigit/256+1, 1 )) AS varbinary(max));
				set @dstDigit %= 256;
				set @carry_flag = 'TRUE';
			END
			ELSE
			BEGIN
				IF @iterator = 1
				BEGIN
					set @string_bin = CAST(STUFF(@string_bin, @iterator, 1, '') AS varbinary(max));
					set @string_len = @string_len - 1;
					set @iterator = @iterator - 1;
				END
				ELSE
				BEGIN
					set @string_bin = CAST(STUFF(@string_bin, @iterator, 1, 0x30) AS varbinary(max));
				END
			END

			set @iterator = @iterator + 1;
		END

		IF @dstLen = 0
		BEGIN
			set @base62_bin = CAST((@dstDigit&0xff) AS varbinary(1));
		END
		ELSE
		BEGIN
			set @base62_bin = CAST((@dstDigit&0xff) AS varbinary(1)) + @base62_bin;
		END
		set @dstLen = @dstLen + 1;

		--print @base62_bin;

	END
	
	return @base62_bin;
END

GO

--##############################################################################

IF EXISTS (SELECT *
	FROM   sys.objects
	WHERE  object_id = OBJECT_ID(N'[dbo].[fn_uuid_to_base62]')
	AND type IN ( N'FN' ))
	DROP FUNCTION [dbo].[fn_uuid_to_base62]

GO

CREATE FUNCTION [dbo].[fn_uuid_to_base62](@uuid [varchar](36))
RETURNS [varchar](22) WITH EXECUTE AS CALLER
AS
BEGIN
	declare @base62_string varchar(22) = dbo.fn_base62encode(dbo.fn_uuid2hex(@uuid));
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

CREATE FUNCTION [dbo].[fn_base62_to_uuid](@base [varchar](22))
RETURNS [varchar](36) WITH EXECUTE AS CALLER
AS
BEGIN
	declare @hex_string varchar(36) = dbo.fn_hex2uuid(dbo.fn_base62decode(@base));
	return @hex_string;
END

GO

--##############################################################################

select dbo.fn_uuid2hex('BE778A5C-0AC0-45E4-A15B-4DD7687C6293'), 0x93627C68D74D5BA145E40AC0BE778A5C;
select dbo.fn_hex2uuid(0x93627C68D74D5BA145E40AC0BE778A5C), 'BE778A5C-0AC0-45E4-A15B-4DD7687C6293';

GO

--##############################################################################

select dbo.fn_base62encode(0x93627C68D74D5BA145E40AC0BE778A5C), '4U6sZo9kFS2weMLGMzWbTo';
select dbo.fn_base62encode(dbo.fn_uuid2hex('BE778A5C-0AC0-45E4-A15B-4DD7687C6293')), '4U6sZo9kFS2weMLGMzWbTo';

GO

--##############################################################################

select dbo.fn_base62decode('4U6sZo9kFS2weMLGMzWbTo'), 0x93627C68D74D5BA145E40AC0BE778A5C;
select dbo.fn_hex2uuid(dbo.fn_base62decode('4U6sZo9kFS2weMLGMzWbTo')), 'BE778A5C-0AC0-45E4-A15B-4DD7687C6293';

GO

--##############################################################################

select dbo.fn_base62_to_uuid('4U6sZo9kFS2weMLGMzWbTo'), 'BE778A5C-0AC0-45E4-A15B-4DD7687C6293';
select dbo.fn_uuid_to_base62('BE778A5C-0AC0-45E4-A15B-4DD7687C6293'), '4U6sZo9kFS2weMLGMzWbTo';

GO

--##############################################################################

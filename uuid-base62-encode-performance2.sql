
declare @base_data varchar(22) = '4U6sZo9kFS2weMLGMzWbTo';
declare @binary_data varchar(36) = 'BE778A5C-0AC0-45E4-A15B-4DD7687C6293';

declare @base varchar(max);
declare @bin varchar(max);

declare @timestamp_start DATETIME;
declare @timestamp_temp DATETIME;
declare @timestamp_stop bigint;

declare @turns int;
declare @interator int;

set @timestamp_stop = 0;
set @turns = 1000;
set @interator = 0;
WHILE @interator < @turns
BEGIN
	set @timestamp_start = GETDATE();
	set @base = dbo.fn_uuid_to_base62(@binary_data);
	set @timestamp_temp = GETDATE();
	set @timestamp_stop = (@timestamp_stop + DATEDIFF(millisecond, @timestamp_start, @timestamp_temp));
	set @interator = @interator + 1;
END
print (@timestamp_stop / @turns);

set @timestamp_stop = 0;
set @turns = 1000;
set @interator = 0;
WHILE @interator < @turns
BEGIN
	set @timestamp_start = GETDATE();
	set @bin = dbo.fn_base62_to_uuid(@base_data);
	set @timestamp_temp = GETDATE();
	set @timestamp_stop = (@timestamp_stop + DATEDIFF(millisecond, @timestamp_start, @timestamp_temp));
	set @interator = @interator + 1;
END
print (@timestamp_stop / @turns);

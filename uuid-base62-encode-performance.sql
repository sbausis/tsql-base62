declare @timestamp1 DATETIME;
declare @timestamp2 DATETIME;
declare @timestamp3 DATETIME;
declare @elapsedTime1 int;
declare @elapsedTime2 int;

declare @binary_data varbinary(512) = 0x93627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA145E40AC0BE778A593627C68D74D5BA1;
declare @base_data varchar(344) = 'U9KPHBU420U9BbxfwAU5YW3lZDc20qnG9wOmTIU9R4awdwnjgYI9TvSQ2NCVIN573twLwM9WzpOMaFNZHfER5RP3WsVgVthTElzsIMCDhqy7hS2013hYDvIv06Gz1oAfLnhyrJx5ZYfJhnwMjkUxFzjpn6DDYldFNAXPK93DrvAC2jPMgPmT9PXSMKCO3kAjvgfVoqc3zeoOjs5Ay1RUhOJ3ZAh2WwZiOPn7He8EIi3eYsoXuirPLUZdC3dDGFznQLqKjHofZbHyMoktAp8u0Nj7o2Dkt3a4b1ZM0xEbYYqdGsNBxSdoqPO6j7efa5VxsLAlH3GV0PXZcVQoVT7pllQ1';

SET @timestamp1 = GETDATE();

declare @base varchar(max) = dbo.fn_base62encode(@binary_data);

set @timestamp2 = GETDATE();

declare @bin varbinary(max) = dbo.fn_base62decode(@base_data);

set @timestamp3 = GETDATE();

set @elapsedTime1 = DATEDIFF(millisecond,@timestamp1, @timestamp2);
set @elapsedTime2 = DATEDIFF(millisecond,@timestamp2, @timestamp3);

print @base_data;
print @base;
print @elapsedTime1;

print @binary_data;
print @bin;
print @elapsedTime2;
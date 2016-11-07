--������� ��� ����� ����������� �� ���� ����������
--http://pmntrade.ru/trades_history.html

--������ �� �������� �� QLUA
dofile (getScriptPath() .. "\\quik_table_wrapper.lua")

--[[
������ ������� �� sqlite, ������� �� ���� � ������� PnL �� ������� ���������.
� ������� � � ������. ����� ��������� �����, ����� �������� ��������� ���� ����
]]

local sqlite3 = require("lsqlite3")
local db = sqlite3.open(getScriptPath() .. "\\positions.db")
--local db = sqlite3.open_memory()

-- ��������� --

-- ���������� ���������� --

--������� �������
local t 
--��� dll ����� ��� ������ � �������� ������� ������. ��� ������ ����������� buy/sell
local bit = require"bit"

--�������, � ������� ����� ������� �� ������, ������� ��� ���������� � OnTrade()
--�������� � ���, ��� OnTrade() ���������� ����� ������ ���� ��� �������� ������ � ���������,
--������� ���� ���������, ��� �� ������ ��� ����������, ����� �� �������� ����� � �������.
local currentDeals = {}

is_run = true


--SERVICE

--���� ������ �� ������ trade_num � ������� ���� ������
--���������
--  num - ����� ������
function find_current_deal(num)
  for key, value in pairs(currentDeals) do
    --message(key)
    --message(value)
    if value == num then
      return 1
    end
  end
  return 0
end

--���������� ���� ������ � ��������� ������� '6.11.2016'
function get_trade_date(trade)
  local date = trade.datetime.day..'.'..trade.datetime.month..'.'..trade.datetime.year
  return date
end

--���������� ���� ������ � ��������� ������� '10.26.13'
function get_trade_time(trade)
  local time = trade.datetime.hour..':'..trade.datetime.min..':'..trade.datetime.sec
  return time
end


--������������� �������
function recalcPosition(row)

  local priceOpen = tonumber(t:GetValue(row, 'priceOpen').image)
  local priceClose = tonumber(t:GetValue(row, 'priceClose').image)
  local quantity = tonumber(t:GetValue(row, 'quantity').image)
  
  if priceOpen==nil then
    priceOpen=0
  end
  if priceClose==nil then
    priceClose=0
  end
  if quantity==nil then
    quantity=0
  end
  
  local PnL = 0
  
  local direction = tostring(t:GetValue(row, 'operation').image)
  --message(direction)
  
  --if direction=='' then
  --  return 0
  --end
  
  --if direction == 'buy' then
  if quantity > 0 then
    PnL = priceClose - priceOpen
  else
    PnL = priceOpen - priceClose
  end
  
  local Total_PnL = math.ceil(PnL*quantity*1000)/1000
  
  t:SetValue(row, 'profitpt', tostring(Total_PnL))
  
  --����� �������� �������� ���������� ��������� ����������� �����������
  --������� �������� ���� �� 1 ���, ����� ��������� �� 10 ���, ������ ���
  --������� ceil ��������� �� ������ � ���� �� ��������� � ����, �������� 0.05 �� ������� ����!
  
  local PnL_percent = math.ceil ((PnL*1000000)/priceOpen)/10000   --������ ����� �� ������
  
  t:SetValue(row, 'profit %', tostring(PnL_percent))
  --��������� ���� ������ � ����������� �� ������� ��� ������
  
  --��� ��� ������� ����
  
  --RGB(NUMBER red, NUMBER green, NUMBER blue)
  --[[
  b_color = RGB(255, 0, 0)
  f_color = 0
  sel_b_color = RGB(255, 255, 255)
  sel_f_color = RGB(0, 0, 0)
  if PnL > 0 then
    b_color = RGB(230, 255, 230)  --green
    SetColor(t.t_id, row, QTABLE_NO_INDEX, b_color, f_color, sel_b_color, sel_f_color)
  else
    b_color = RGB(255, 230, 230)  --red
    SetColor(t.t_id, row, QTABLE_NO_INDEX, b_color, f_color, sel_b_color, sel_f_color)
  
  end
  --]]
  
  --��� ��� ������ ����
  ---[[
  local b_color = RGB(27, 27, 27)         --���� ���� ������
  local f_color = RGB(100, 100, 100)      --���� ������ ������
  local sel_b_color = RGB(30, 30, 30)     --���� ���� ��������� ������
  local sel_f_color = RGB(200, 200, 200)  --���� ������ ��������� ������
  if PnL > 0 then
    --b_color = RGB(30, 30, 30)  --green 
    f_color = RGB(110, 180, 110)
    sel_f_color = RGB(110, 180, 110)  --���� ������ ��������� ������
    SetColor(t.t_id, row, QTABLE_NO_INDEX, b_color, f_color, sel_b_color, sel_f_color)
  else
    --b_color = RGB(20, 20, 20)  --red 
    f_color = RGB(245, 150, 150)
    sel_f_color = RGB(245, 150, 150) 
    SetColor(t.t_id, row, QTABLE_NO_INDEX, b_color, f_color, sel_b_color, sel_f_color)
  
  end
  --]]
  
  
end

--������� ���������� true, ���� ��� [index] ���������� � 1 (����� �� �������� some_callbacks.lua)
--������ ������ ��� ����������� �����������
--if bit_set(flags, 2) then
--		t["sell"]=1
--	else
--		t["buy"] = 1
--	end
--
function bit_set( flags, index )
  local n=1
  n=bit.lshift(1, index)
  if bit.band(flags, n) ~=0 then
    return true
  else
    return false
  end
end

-- ���������� ������ ������ ������ �������� ������� (��������� �� ������ OPEN)
function findFirstOpenPosRow()
    
    --��������� ���������� ����� � ������� ������  
    local rows = t:GetSize(t.t_id)
  
    --����� ������� ������� ������
    for row=1, rows, 1 do
      
      --����, ��� ���������� �������� �������
      if t:GetValue(row,'dateOpen').image == 'OPEN' then
        return (row + 1)
      end
    end
    
    return 99999999
end

-- ���������� ������ ������ ������ �������� ������� (��������� �� ������ CLOSED)
function findFirstClosedPosRow()
    
    --��������� ���������� ����� � ������� ������  
    local rows = t:GetSize(t.t_id)
  
    --����� ������� ������� ������
    for row=1, rows, 1 do
      
      --����, ��� ���������� �������� �������
      if t:GetValue(row,'dateOpen').image == 'CLOSED' then
        return (row + 1)
      end
    end
    
    return 99999999
end





--��������� �������� �������
function loadClosedPositions()

	loadClosedFifoPositions(0)
	loadClosedFifoPositions(1)
	
end

--��������� � ������� �������� �������. ������ �� sqlite
function loadOpenPositions()

  loadOpenFifoPositions(0)--long
  loadOpenFifoPositions(1)--short
  
end

--��������� ������� �� sqlite
function loadPositions()

  --�������� �������
  
  local row = t:AddLine()
  --��������� �������� �������
  
  t:SetValue(row, 'dateOpen', "CLOSED")
  t:SetValue(row, 'timeOpen', "POSITIONS")

  loadClosedPositions()
  
  --�������� �������
  
  local row = t:AddLine()
  --��������� �������� �������
  
  t:SetValue(row, 'dateOpen', "OPEN")
  t:SetValue(row, 'timeOpen', "POSITIONS")
  
  loadOpenPositions()
  
end

--������� ������� ������ 
function clearTable()
  
  local rows = t:GetSize(t.t_id)

  for row = rows, 1, -1 do

    DeleteRow(t.t_id, row)
  end  
  
end

--������� �� ������� ������ �������� �������. �.�. ������, ���� ��������� OPEN POSITIONS
function clearOpenPositions()
  
  local fr = findFirstOpenPosRow()
  
  local rows = t:GetSize(t.t_id)

  for row = rows, fr, -1 do

    DeleteRow(t.t_id, row)
  end  
  
end

--������� �� ������� ������ �������� �������. �.�. ������, ���� ��������� CLOSED POSITIONS � ���� OPEN POSITIONS
function clearClosedPositions()
  
  local f_c_r = findFirstClosedPosRow()
  local f_o_r = findFirstOpenPosRow()
  
  local rows = t:GetSize(t.t_id)

  for row = f_o_r-2, f_c_r, -1 do

    DeleteRow(t.t_id, row)
  end  
  
end

--FIFO

--�������� ������� �������� ������ ����, ���������� �� ������ ������
--���������
--  isShort - in - integer - 0/1 long/short
function getRestsFIFO(client_code, sec_code, comment, isShort)

  sql=[[SELECT 
          
         --���������
          dim_client_code,
          dim_sec_code,  
          dim_class_code,  
          dim_trade_num, 
          dim_brokerref,
          
          --�������
          SUM(res_qty) AS qty,  
          SUM(res_value) AS value
          
       FROM
          fifo_long
       WHERE
          dim_sec_code = '&sec_code'
          AND
          dim_client_code = '&client_code'
          AND 
          dim_brokerref = '&comment' 
          
       GROUP BY
          dim_client_code,
          dim_sec_code,  
          dim_class_code,  
          dim_trade_num, 
          dim_brokerref
       
       HAVING 
          SUM(res_qty) <> 0  
          AND SUM(res_value) <> 0
          
       ORDER BY
          dim_trade_num
       ]]
         
    sql = string.gsub (sql, '&sec_code', sec_code)
    sql = string.gsub (sql, '&client_code', client_code)
    sql = string.gsub (sql, '&comment', comment)
  
    --������ ��������
    if isShort == 1 then
      sql = string.gsub (sql, 'fifo_long', 'fifo_short')
    end
    
    --message(sql)
    
   local row = 0
   local rests={}
      
   local r_count = 1
   for row in db:nrows(sql) do 
      
      --message(tostring(r_count))
      rests[r_count] = {}
      rests[r_count]['dim_client_code'] =row.dim_client_code
      rests[r_count]['dim_sec_code']    =row.dim_sec_code  
      rests[r_count]['dim_class_code']  =row.dim_class_code  
      rests[r_count]['dim_trade_num']   =row.dim_trade_num 
      rests[r_count]['dim_brokerref']   =row.dim_brokerref
      
          --�������
      rests[r_count]['qty']         =row.qty  
      rests[r_count]['value']       =row.value
      
      r_count = r_count + 1
   end
   
   return rests  
end

--�������� ������ �� ����
function makeFifo(trade)

    --��������� ����������� ������
    local dir = ''
    if bit_set(trade.flags, 2) then
      dir = 'sell'
    else
      dir = 'buy'
    end
    
    if dir == 'buy' then
    
      --buy. decrease short
      local restShort = getRestsFIFO(trade.client_code, trade.sec_code, trade.brokerref, 1)
      
      --���������� �� ������, �� ������� ����� ������� �����
      local total_qty_to_decrease = trade.qty
      
      
      --������� ����� �� �������� �� ��������
      local rest_count = 1
      while rest_count <= table.maxn(restShort) and total_qty_to_decrease > 0 do
        
        --��������� ����������, ������ ���� ��� �� �������
        if restShort[rest_count]['qty'] ~= 0 then
        
          --����������� �������� ��� ������    
          local factor = 1
        
          --������� � ������ �������������, ������� �������� �� -1
          if -1*restShort[rest_count]['qty'] >= total_qty_to_decrease then 
            -- ������� ������ ������, ��� ��� ���� �������
            factor = total_qty_to_decrease / -1*restShort[rest_count]['qty']
          else
            factor = 1
          end
          
          --����� �������
          
          local qty_decreased = -1*restShort[rest_count]['qty'] * factor
          local value_decreased = -1*restShort[rest_count]['value'] * factor
          
          --����� ������ � ������� ������
          
          local k="'"
          local sql='INSERT INTO fifo_short '..
          '(dim_client_code, dim_sec_code, dim_class_code, dim_trade_num, dim_brokerref,'.. 
          'res_qty, res_value, '..
          'close_trade_num, close_date, close_time, close_price, close_qty, close_value, close_price_step, close_price_step_price'..
          ')'..
          ' VALUES('.. 
                  --���������
                  k..restShort[rest_count]['dim_client_code']      ..k..','..
                  k..restShort[rest_count]['dim_sec_code']         ..k..','..  
                  k..restShort[rest_count]['dim_class_code']       ..k..','..  
                  restShort[rest_count]['dim_trade_num']           ..','..
                  k..restShort[rest_count]['dim_brokerref']        ..k..' ,'..
  
                  --�������
                  qty_decreased                ..','..  
                  value_decreased              ..','..
  
                  --��������� - ������ ������, ������� ���������
                  
                  --'close_trade_num, close_date, close_time, close_price, close_qty, close_value, close_price_step, close_price_step_price
                  
                  trade.trade_num..','.. 
                  k..get_trade_date(trade)..k..','..
                  k..get_trade_time(trade)..k..','..
                  trade.price..','..
                  trade.qty..','..
                  trade.price*trade.qty..','..
                  getParamEx (trade.class_code, trade.sec_code, 'SEC_PRICE_STEP').param_value..','..
                  getParamEx (trade.class_code, trade.sec_code, 'STEPPRICE').param_value..
                   
                  ');'          
          --message(sql)                     
           db:exec(sql)          
          
          -- ��������, ����� �� ����� ��� ��������� "�������, ��������������� ��������� ������"        
          
          total_qty_to_decrease  = total_qty_to_decrease - qty_decreased      
        end
          
        rest_count = rest_count + 1
        
      end           
      
      --buy. increase long
      
      if total_qty_to_decrease > 0 then

        local k="'"
  
         local sql='INSERT INTO fifo_long '..
          --���������� ����, ������� ����� ���������
          '(dim_client_code, dim_sec_code, dim_class_code, dim_trade_num,dim_brokerref,'..
          'res_qty, res_value,'..
          'attr_date, attr_time, attr_price, attr_trade_currency, attr_accruedint, attr_trans_id,'..
          'attr_order_num,attr_lot,attr_exchange_comission)'..
  
          ' VALUES('..
           
          --���������
          k..trade.client_code      ..k..','..--  ��� �������
          k..trade.sec_code         ..k..','..--  ��� ������ ������  
          k..trade.class_code       ..k..','..--  ��� ������  
          trade.trade_num           ..','.. --  ����� ������ � �������� ������� 
          k..trade.brokerref        ..k..' ,'..--  �����������,'.. ������: <��� �������>/<����� ���������>
          
          --�������
          total_qty_to_decrease     ..','..  
          total_qty_to_decrease * trade.price  ..','..
          
          --���������  
          k..get_trade_date(trade)..k..','..--  ���� � �����
          k..get_trade_time(trade)..k..','..--  ���� � �����
          trade.price               ..','.. --  ����
          k..trade.trade_currency..k..','..--  ������
          trade.accruedint          ..','..--  ����������� �������� �����
          k..trade.trans_id..k      ..','..--  ������������� ����������
          trade.order_num           ..','..--  ����� ������ � �������� �������  
          getParamEx (trade.class_code, trade.sec_code, 'LOTSIZE').param_value  ..','..  
          trade.exchange_comission  ..--  �������� �������� ����� (����)  
          ');'          
                     
        db:exec(sql)  
      
      end
      
    elseif dir == 'sell' then
    
      --sell. decrease long
      
      --������� �������� ������� �������
      local restLong = getRestsFIFO(trade.client_code, trade.sec_code, trade.brokerref, 0)
      
      --���������� �� ������, �� ������� ����� ������� �����
      local total_qty_to_decrease = trade.qty
      
      --������� ����� �� �������� �� ��������
      local rest_count = 1
      while rest_count <= table.maxn(restLong) and total_qty_to_decrease > 0 do
        
        --��������� ����������, ������ ���� ��� �� �������
        if restLong[rest_count]['qty'] ~= 0 then
        
          --����������� �������� ��� ������    
          local factor = 1
        
          if restLong[rest_count]['qty'] >= total_qty_to_decrease then 
            -- ������� ������ ������, ��� ��� ���� �������
            factor = total_qty_to_decrease / restLong[rest_count]['qty']
          else
            factor = 1
          end
          
          --����� �����
          
          local qty_decreased = restLong[rest_count]['qty'] * factor
          local value_decreased = restLong[rest_count]['value'] * factor
          --message(restLong[rest_count]['dim_brokerref'])
          --����� ������ � ������� ������
          --message(restLong[rest_count]['dim_brokerref'])
          local k="'"
          local sql='INSERT INTO fifo_long '..
          '(dim_client_code, dim_sec_code, dim_class_code, dim_trade_num, dim_brokerref,'.. 
          'res_qty, res_value, '..
          'close_trade_num, close_date, close_time, close_price, close_qty, close_value, close_price_step, close_price_step_price'..
          ')'..
          ' VALUES('.. 
                  --���������
                  k..restLong[rest_count]['dim_client_code']      ..k..','..
                  k..restLong[rest_count]['dim_sec_code']         ..k..','..  
                  k..restLong[rest_count]['dim_class_code']       ..k..','..  
                  restLong[rest_count]['dim_trade_num']           ..','..
                  k..restLong[rest_count]['dim_brokerref']        ..k..','..
  
                  --�������
                  -1*qty_decreased                ..','..  
                  -1*value_decreased              ..','..
  
                  --��������� - ������ ������, ������� ���������
                  
                  --'close_trade_num, close_date, close_time, close_price, close_qty, close_value, close_price_step, close_price_step_price
                  
                  trade.trade_num..','.. 
                  k..get_trade_date(trade)..k..','..
                  k..get_trade_time(trade)..k..','..
                  trade.price..','..
                  trade.qty..','..
                  trade.price*trade.qty..','..
                  getParamEx (trade.class_code, trade.sec_code, 'SEC_PRICE_STEP').param_value..','..
                  getParamEx (trade.class_code, trade.sec_code, 'STEPPRICE').param_value..
                   
                  ');'          
          --message(sql)                     
           db:exec(sql)            
          -- ��������, ����� �� ����� ��� ��������� "�������, ��������������� ��������� ������"        
          
          total_qty_to_decrease  = total_qty_to_decrease - qty_decreased      
        end
          
        rest_count = rest_count + 1
        
      end      
      
      --sell. increase short
      
      --���� � ������ ��� �������� ����������, ��������� ����
    
      if total_qty_to_decrease > 0 then

        local k="'"
        
        local sql='INSERT INTO fifo_short '..
          --���������� ����, ������� ����� ���������
              '(dim_client_code, dim_sec_code, dim_class_code, dim_trade_num, dim_brokerref,'..
                'res_qty, res_value,'..
                'attr_date,attr_time, attr_price,attr_trade_currency,attr_accruedint,attr_trans_id,'..
                'attr_order_num,attr_lot,attr_exchange_comission)'..
        
                ' VALUES('..
                 
                --���������
                k..trade.client_code      ..k..','..--  ��� �������
                k..trade.sec_code         ..k..','..--  ��� ������ ������  
                k..trade.class_code       ..k..','..--  ��� ������  
                trade.trade_num           ..','.. --  ����� ������ � �������� ������� 
                k..trade.brokerref        ..k..' ,'..--  �����������,'.. ������: <��� �������>/<����� ���������>
                
                --�������
                -1*total_qty_to_decrease                 ..','..--  ���������� ����� � ��������� ������ � �����  
                -1*total_qty_to_decrease * trade.price   ..','..
                
                --���������  
                k..get_trade_date(trade)..k..','..--  ���� � �����
                k..get_trade_time(trade)..k..','..--  ���� � �����
                trade.price               ..','.. --  ����
                k..trade.trade_currency..k..','..--  ������
                trade.accruedint          ..','..--  ����������� �������� �����
                k..trade.trans_id..k      ..','..--  ������������� ����������
                trade.order_num           ..','..--  ����� ������ � �������� �������  
                getParamEx (trade.class_code, trade.sec_code, 'LOTSIZE').param_value                       ..','..  
                trade.exchange_comission  ..--  �������� �������� ����� (����)  
                ');'          
                           
         db:exec(sql)  
            
      end
      
    end
    
end

--  ����������� ������ �� ���� � ������� ������

function addRowFromFIFO(sqliteRow, isShort)

  local row = t:AddLine()
  t:SetValue(row, 'dateOpen', sqliteRow.date)
  t:SetValue(row, 'timeOpen', sqliteRow.time)
  t:SetValue(row, 'tradeNum', sqliteRow.dim_trade_num)
  
  t:SetValue(row, 'secCode', sqliteRow.dim_sec_code)
  t:SetValue(row, 'classCode', sqliteRow.dim_class_code)
  
  if isShort==1 then
    t:SetValue(row, 'operation', 'sell')
  else
    t:SetValue(row, 'operation', 'buy')
  end
  
  t:SetValue(row, 'quantity', tostring(sqliteRow.qty))
  t:SetValue(row, 'amount', tostring(sqliteRow.value))
  t:SetValue(row, 'priceOpen', tostring(sqliteRow.price))
  
  t:SetValue(row, 'dateClose', '')
  t:SetValue(row, 'timeClose', '')
  t:SetValue(row, 'priceClose', tostring(sqliteRow.price))
  
  t:SetValue(row, 'commission', 0)
  t:SetValue(row, 'accrual', 0)
  
  t:SetValue(row, 'profit %', 0)
  t:SetValue(row, 'profit', 0)
  t:SetValue(row, 'profitpt', 0)
  
  t:SetValue(row, 'days', 0)
  t:SetValue(row, 'comment', sqliteRow.brokerref)
  
  recalcPosition(row)
  
end

function loadOpenFifoPositions(isShort)

  local sql=[[SELECT 
          
         --���������
          dim_client_code,
          dim_sec_code,  
          dim_class_code,  
          dim_brokerref,
          
          --�������
          SUM(res_qty) AS qty,  
          SUM(res_value) AS value,
          SUM(res_value)/SUM(res_qty) AS price
          
       FROM
          fifo_long
          
       GROUP BY
          dim_client_code,
          dim_sec_code,  
          dim_class_code,  
          dim_brokerref
       
       HAVING 
          SUM(res_qty) <> 0  
          AND SUM(res_value) <> 0
          
       ORDER BY
          dim_client_code,
          dim_sec_code,  
          dim_class_code,  
          dim_brokerref       
        ]]
  
    --������ ��������
    if isShort == 1 then
      sql = string.gsub (sql, 'fifo_long', 'fifo_short')
    end
    
    --message(sql)
    
   --local row = 0
   
   for row in db:nrows(sql) do 
      addRowFromFIFO(row, isShort)
      
   end
  
end

function addRowFromFIFO_close(sqliteRow, isShort)

  local row = t:AddLine()
  
  t:SetValue(row, 'dateOpen', sqliteRow.date)
  t:SetValue(row, 'timeOpen', sqliteRow.time)
  t:SetValue(row, 'tradeNum', sqliteRow.dim_trade_num)
  
  t:SetValue(row, 'secCode', sqliteRow.dim_sec_code)
  t:SetValue(row, 'classCode', sqliteRow.dim_class_code)
  
  if isShort==1 then
    t:SetValue(row, 'operation', 'sell')
  else
    t:SetValue(row, 'operation', 'buy')
  end
  
  t:SetValue(row, 'quantity', tostring(sqliteRow.qty))
  t:SetValue(row, 'amount', tostring(sqliteRow.value))
  t:SetValue(row, 'priceOpen', tostring(sqliteRow.price))
  
  t:SetValue(row, 'dateClose', sqliteRow.close_date)
  t:SetValue(row, 'timeClose', sqliteRow.close_time)
  t:SetValue(row, 'priceClose', sqliteRow.close_price)
  
  t:SetValue(row, 'commission', 0)
  t:SetValue(row, 'accrual', 0)
  
  t:SetValue(row, 'profit %', 0)
  t:SetValue(row, 'profit', 0)
  t:SetValue(row, 'profitpt', 0)
  
  t:SetValue(row, 'days', 0)
  t:SetValue(row, 'comment', sqliteRow.dim_brokerref)
  
  recalcPosition(row)
  
end

function loadClosedFifoPositions(isShort)

  local sql=[[SELECT 
          
         --���������
          dim_client_code,
          dim_sec_code,  
          dim_class_code,  
          dim_brokerref,
          dim_trade_num,
          
          --�������
          res_qty AS qty,  
          res_value AS value,
          
          --���������
          res_value/res_qty as price,
          attr_date as dateOpen,
          attr_time as timeOpen,
          
          close_trade_num,
          close_date,
          close_time,
          close_price,
          close_qty,
          close_value,
          close_price_step,
          close_price_step_price REAL          
          
       FROM
          fifo_long
       
       WHERE 
          res_qty < 0  
          
       ORDER BY
          dim_trade_num,
          dim_client_code,
          dim_sec_code,  
          dim_class_code,  
          dim_brokerref
                 
        ]]
  
    --������ ��������
    if isShort == 1 then
      sql = string.gsub (sql, 'fifo_long', 'fifo_short')
      sql = string.gsub (sql, 'res_qty < 0', 'res_qty > 0')
    end
    
    --message(sql)
    
   --local row = 0
   for row in db:nrows(sql) do 
      addRowFromFIFO_close(row, isShort)
   end
  
end

-- ����������� �������

--���������� ���� �������
function showTable()

  t:Show()
  
end

--������� ������� ��� ����������� ������� � �������
function createTable()

  -- ������� ��������� QTable
  t = QTable.new()
  if not t then
    message("error!", 3)
    return
  else
    --message("table with id = " ..t.t_id .. " created", 1)
  end
  
  t:AddColumn("dateOpen",   QTABLE_STRING_TYPE, 10)   --1
  t:AddColumn("timeOpen",   QTABLE_STRING_TYPE, 10)   --2
  t:AddColumn("tradeNum",  QTABLE_STRING_TYPE, 10)   --2
  t:AddColumn("secCode",    QTABLE_STRING_TYPE, 15)   --3
  t:AddColumn("classCode",  QTABLE_STRING_TYPE, 10)   --4
  
  --��� ���������� QTABLE_CACHED_STRING_TYPE � QTABLE_STRING_TYPE? ����� ������������ ��� ��� ������ ������?
  --��� ������������� QTABLE_CACHED_STRING_TYPE � ������ ������� �������� ������ �� ����������� ������� ���������� 
  --��������� ��������, ������� ����������� �� ���� ���������� ������. ��� �������� ������ ��� ������������ 
  --������������� ������������� ��������. ��������, ���� �� ������ ������� ������ ������� ���� ������, �� ���� 
  --"����������� ������" ����� ��������� �������� "�������" ��� "�������". � ���� ������ ������������� 
  --QTABLE_CACHED_STRING_TYPE ��� ������� ����� �������� �����������.   
  t:AddColumn("operation",  QTABLE_CACHED_STRING_TYPE, 10)    --5   --buy/sell
  
  t:AddColumn("quantity",   QTABLE_INT_TYPE, 10)        --6
  t:AddColumn("amount",     QTABLE_DOUBLE_TYPE, 10)     --7
  t:AddColumn("priceOpen",  QTABLE_DOUBLE_TYPE, 20)     --8
  
  t:AddColumn("dateClose",  QTABLE_STRING_TYPE, 10)     --9
  t:AddColumn("timeClose",  QTABLE_STRING_TYPE, 10)     --10
  t:AddColumn("priceClose", QTABLE_DOUBLE_TYPE, 20)     --11  --����� ������������ ������� ����
  
  t:AddColumn("commission", QTABLE_DOUBLE_TYPE, 10)     --12
  
  t:AddColumn("accrual",    QTABLE_DOUBLE_TYPE, 10)     --13
  
  t:AddColumn("profit %",   QTABLE_DOUBLE_TYPE, 10)     --14
  t:AddColumn("profit",     QTABLE_DOUBLE_TYPE, 10)     --15  --� ������ ��� ������ (�������)
  t:AddColumn("profitpt",    QTABLE_DOUBLE_TYPE, 10)     --15  --� �������, �������� Ri
  
  t:AddColumn("days",       QTABLE_INT_TYPE, 10)        --16  --���� � �������
  
  t:AddColumn("comment",    QTABLE_STRING_TYPE, 20)     --17

  t:SetCaption("Trade history")
  
end



-- ����������� ������� ----

function OnInit(s)

  createTable()
  
  showTable()
  
  loadPositions()
    
end

function OnStop(s)
  DestroyTable(t.t_id)
  is_run = false
  return 1000
end

function OnQuote(class_code, sec_code)
	--������� ��������� � ������� PnL
end

function OnTransReply(repl)
end

function OnTrade(trade)
	--�������� ������ � ������� ������������
	--������� ���������, ��� �� ��� ���

	if find_current_deal(trade.trade_num) == 0 then
		
		table.insert(currentDeals, trade.trade_num)
		
		--��� ����� - �������� ������� � ������� t
		--addRowTrade(trade)
		
	
    
    --�������� ������� � sqlite
    --insertTradeIntoPositions(trade)
		
		--�������� ������� � ����
		makeFifo(trade)
		
	end

  --������������� ������� �������� �������

  --������� ��� �������
  
  --clearClosedPositions()
  
  --����� �������� ��� ��������
  
  --loadClosedPositions()
  
	
	--������������� ������� �������� �������

	--������� ��� �������
	
	--clearOpenPositions()
	
	--����� �������� ��� ��������
	
	--loadOpenPositions()
	
	clearTable()
	
	loadPositions()
	
end






-- +----------------------------------------------------+
--                  MAIN
-- +----------------------------------------------------+


-- ������� ��������� ������ ��� ��������� ������� � �������. ���������� �� main()
--(���, ������� �������, ���������� ����� �� ������� ������)
--���������:
--  t_id - ����� �������, ���������� �������� AllocTable()
--  msg - ��� �������, ������������ � �������
--  par1 � par2 � �������� ���������� ������������ ����� ��������� msg, 
--
--������� ������ ������������� ����� main(), ����� - ������ �� ��������������� ��� �������� ����
local f_cb = function( t_id,  msg,  par1, par2)
  
  if (msg==QTABLE_CLOSE)  then
    DestroyTable(t.t_id)
    is_run = false
    --message("����",1)
  end

end 

-- �������� ������� ������. ����� ����������� ��������� � �������������� �������
function main()

  while is_run do
  
    local rows = t:GetSize(t.t_id)
      
    --����� ������, � ������� ���������� �������� �������.
    --���, ��� ������ (����), ��� - �������� �������. � ��� �� ���� ��������� ��������� � ������������� �������.
    local openPosStartRow = 99999999
    openPosStartRow = findFirstOpenPosRow()
    
    --����� ������� ������� ������
    for row=1, rows, 1 do

      --��� �����, ����������� ����, ��������� ���������
      if row >= openPosStartRow then
        --message(row)
        --������� ���� ��������� ������ 
        local tparam = getParamEx (t:GetValue(row,'classCode').image, t:GetValue(row,'secCode').image, 'last')
        
        --��������� ������� ���� � �������
        
        --����� ������ �� ��������
        --t:SetValue(row, 'priceClose', tostring(tparam.param_value))
        --������� ���������� ���� (��������� �������� ������� �� ���������!)
        --����� - �������� �� �����������:(
        --message(tparam.param_value)
        
        t:SetValue(row, 'priceClose', tostring(tparam.param_value)) 
        --���������� �������       
        recalcPosition(row)
          
      end
      
    end
    
    SetTableNotificationCallback (t.t_id, f_cb)
    
    sleep(1000)
  end
  
end


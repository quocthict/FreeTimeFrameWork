====================================

-- show data in table --
select * from source_employees
select * from module_info

====================================

-- Pick up free time of staff
	-- step 1: create table free_time_employees_target
	-- step 2: take the free time of each employee 

-- step 1: create table free_time_employees_target
create table free_time_employees_target 
		(
		id_employee int,
		working_day date,
		start_free_time timestamp ,
		end_free_time timestamp
		)	

-- step 2: take the free time of each employee
create or replace procedure FigureOutFreeTime() as
$$
	declare 
		vId int4;
		vDay date;
		vStartTime timestamp;
		vEndTime timestamp;
		c1 refcursor; 
	
	begin -- begin 1 
		open c1 for -- c1 chứa dữ liệu cần thiết từ bảng source_employees
			select 
				e.id,
				e.working_day,
				e.work_start_time,
				e.work_end_time
			from source_employees e;
		
		-- raise notice '==========> Start processing !!!';		
		loop -- lặp lại từng dòng trong c1
			fetch next from c1 into vId, vDay,vStartTime, vEndTime;
			exit when not found;			
			-- Ứng với mỗi dòng trong c1 xử lý cho bảng module_info
			declare
				vModuleId int;
				vModuleDay date;
				vModuleStartTime timestamp;
				vModuleEndTime timestamp;
				c2 refcursor ;	
			begin -- begin 2 
				open c2 for 
					select 
						mi.id ,
						mi.working_day ,
						mi.module_start ,
						mi.module_end 
					from module_info mi
					where 
						mi.id = vId and 
						mi.module_start is not null 
					order by mi.module_start asc;
				-- xoa du lieu target ma da sap xep free time cho nhan vien dang ton tai
				delete from free_time_employees_target where vId = id_employee ;
				commit;
				loop -- loop 2
					fetch next from c2 into vModuleId, vModuleDay, vModuleStartTime, vModuleEndTime;
					exit when not found;
				
					-- Trường hợp bắt đầu module sau thời gian làm việc
					if (vStartTime < vModuleStartTime) then 
		--				raise notice 'Truong hop be hon';
						insert into free_time_employees_target 	values 
							(vId,
							vDay,
							vStartTime ,
							vModuleStartTime);
						-- khởi tạo lại work start time để xét cho dòng kế tiếp
						vStartTime := vModuleEndTime ;
					end if;
					
					-- Trường hợp làm song song nhiều module
					if (vStartTime >= vModuleStartTime) then 
						if (vStartTime < vModuleEndTime) then 	
							vStartTime := vModuleEndTime;
						end if;
					end if;
			end loop; -- end loop 2
			
			-- Trường hợp còn thời gian trống cuối buổi ngày làm việc
			if (vStartTime < vEndTime) then 
				insert into free_time_employees_target values 
					(vId,
					vDay,
					vStartTime ,
					vEndTime );					
			end if;		
		end; -- end 2		
		end loop; -- end loop 1
		raise notice 'End';
	end; -- end 1
$$
language plpgsql;

==============================================

call FigureOutFreeTime();
select * from free_time_employees_target 


==============================================
		-- Trial --

create or replace procedure FigureOutFreeTime() 
as
do
$$
declare -- declare 1
	vId int4;
	vDay date;
	vStartTime timestamp;
	vEndTime timestamp;
	c1 refcursor; -- define a cursor c1
	
	-- Be used to mapping datatype of free_time_employees table
	-- trow have 4 fields id, working_day, start_free_time, end_free_time
--	trow1 free_time_employees%rowtype; 

begin -- begin 1 
	
	-- create output table free_time_employees 
--	create temporary table free_time_employees  
--		(
--		id int,
--		working_day date,
--		start_free_time timestamp ,
--		end_free_time timestamp
--		)	
--	select * from free_time_employees 
--	drop table free_time_employees 	
	
	open c1 for -- c1 get data from source_employees table
		select 
			e.id,
			e.working_day,
			e.work_start_time,
			e.work_end_time
		from source_employees e;
	
	raise notice '==========> Start processing !!!';
	
	loop -- loop 1
		fetch next from c1 into vId, vDay,vStartTime, vEndTime;
		exit when not found;
		raise notice '* Employee id = %', vId;	
	
		-- Starting of block 2
		declare
			vModuleId int;
			vModuleDay date;
			vModuleStartTime timestamp;
			vModuleEndTime timestamp;
			c2 refcursor ;
--			trow2 free_time_employees%rowtype;
		begin -- begin 2 
			open c2 for 
				select 
					mi.id ,
					mi.working_day ,
					mi.module_start ,
					mi.module_end 
				from module_info mi
				where 
					mi.id = vId and 
--					mi.id = 10092 and
					mi.module_start is not null 
				order by mi.module_start asc;
			
			loop -- loop 2
				fetch next from c2 into vModuleId, vModuleDay, vModuleStartTime, vModuleEndTime;
--				fetch next from c2 into trow2;
				exit when not found;
--				vModuleStartTime := trow2.start_free_time;
--				vModuleEndTime := trow2.end_free_time;
				raise notice '+++ Module Start-time = %', vModuleEndTime ;
			
				if (vStartTime < vModuleStartTime) then 
	--				raise notice 'Truong hop be hon';
					insert into free_time_employees	values 
						(
						vId,
						vDay,
						vStartTime ,
						vModuleStartTime 
						);
					vStartTime := vModuleEndTime ;
				end if;
				
				-- deal with cases Module_Start_Time = Work_Start_Time or multi modules 
				if (vStartTime >= vModuleStartTime) then 
					vStartTime := vModuleEndTime; 
				end if;
			
				if (vStartTime < vEndTime) then 
					insert into free_time_employees values 
						(
						vId,
						vDay,
						vStartTime ,
						vEndTime 
						);					
				end if;
		
		end loop; -- end loop 2
--		end of block 2
		
		raise notice '--------------------------------';
	
	end; -- end 2
	
	end loop; -- end loop 1
	raise notice 'End';
end; -- end 1
$$
language plpgsql;

call FigureOutFreeTime();



create or replace procedure FigureOutFreeTime() 
as
$$
declare -- declare 1
	vId int4;
	vDay date;
	vStartTime timestamp;
	vEndTime timestamp;
	c1 refcursor; -- define a cursor c1
begin -- begin 1 
	
	-- create output table free_time_employees 
	create temporary table free_time_employees  
		(
		id int,
		working_day date,
		start_free_time timestamp ,
		end_free_time timestamp
		)	
	
	-- Starting of block 1
	open c1 for -- get data from source_employees table
		select 
			e.id,
			e.working_day,
			e.work_start_time,
			e.work_end_time
		from source_employees e;
	
	raise notice '==========> Start processing !!!';
	
	loop -- loop 1
		fetch next from c1 into vId, vDay,vStartTime, vEndTime;
		exit when not found;
--		raise notice '* Employee id = %', vId;	
	
		-- Starting of block 2
		declare
			vModuleId int;
			vModuleDay date;
			vModuleStartTime timestamp;
			vModuleEndTime timestamp;
			c2 refcursor ;

		begin -- begin 2 
			open c2 for 
				select 
					mi.id ,
					mi.working_day ,
					mi.module_start ,
					mi.module_end 
				from module_info mi
				where 
					mi.id = vId and 
					mi.module_start is not null 
				order by mi.module_start asc;
			
			loop -- loop 2
				fetch next from c2 into vModuleId, vModuleDay, vModuleStartTime, vModuleEndTime;
				exit when not found;
				
				-- case 1
				if (vStartTime < vModuleStartTime) then 
					insert into free_time_employees	values 
						(
						vId,
						vDay,
						vStartTime ,
						vModuleStartTime 
						);
					vStartTime := vModuleEndTime ;
				end if;
				
				-- case 2
				if (vStartTime >= vModuleStartTime) then 
					vStartTime := vModuleEndTime; 
				end if;
				
				-- case 3
				if (vStartTime < vEndTime) then 
					insert into free_time_employees values 
						(
						vId,
						vDay,
						vStartTime ,
						vEndTime 
						);					
				end if;
		
		end loop; -- end loop 2
		-- end of block 2
	end; -- end 2
	end loop; -- end loop 1

end; -- end 1
$$
language plpgsql;

call FigureOutFreeTime();

select * from free_time_employees_target 
where id_employee = 11668;

select * from module_info mi 
where id = 11668
and module_start is not null
order by module_start ;

select * from source_employees e 
where id = 11668;


CÃ³ 2 táº­p dá»¯ liá»‡u :
++ Táº­p thá»© nháº¥t gá»“m thá»�i gian check in , check out cá»§a tá»«ng nhÃ¢n viÃªn trong 1 ngÃ y
++ Táº­p thá»© 2 : gá»“m thá»�i gian thá»±c hiá»‡n cÃ¡c module (task) cá»§a tá»«ng nhÃ¢n viÃªn trong 1 ngÃ y 
--> Viáº¿t Procedure Ä‘á»ƒ tÃ¬m ra cÃ¡c khoáº£ng thá»�i gian trá»‘ng (free time) giá»¯a cÃ¡c task mÃ  nhÃ¢n viÃªn Ä‘Ã³ lÃ m trong ngÃ y. 
-> khoáº£ng thá»�i gian nhÃ¢n viÃªn Ä‘ang trá»‘ng task 

8h sÃ¡ng , 17h chiá»�u 
8h sÃ¡ng -> 11h , 13h -> 14h , 15h -> 17h
11h-13h , 14h-15h
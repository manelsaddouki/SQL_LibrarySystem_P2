select * FROM books; 

SELECT * FROM issued_status;
 
--CRUD Operations 

-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books (isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')
 
-- Task 2: Update an Existing Member's Address

select * from members; 
UPDATE members 
SET member_address= '125 Oak St'
where member_id='C103'; 


--Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

delete from issued_status
where issued_id = 'IS121'; 

--Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status
where issued_emp_id='E101'; 

--Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
select issued_emp_id, nb_issued_books
from 
(SELECT issued_emp_id, count(issued_id) as nb_issued_books
from issued_status
group by issued_emp_id)
where nb_issued_books>1; 

--or 
SELECT issued_emp_id, count(issued_id) as nb_issued_books
from issued_status
group by issued_emp_id
having count(issued_id)>1;

--Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
create table nb_issued_books 
as
SELECT ist.issued_book_isbn, ist.issued_book_name, 
b.author, b.publisher, count(ist.issued_id) as nb_issued_books
from issued_status as ist 
join books as b
ON ist.issued_book_isbn = b.isbn
group by ist.issued_book_isbn, ist.issued_book_name, 
b.author, b.publisher; 

--Task 7. Retrieve All Books in a Specific Category:
select isbn, book_title, category
from books as b
where category = 'Classic';

--Task 8: Find Total Rental Income by Category:
select b.category, b.rental_price, 
count(st.issued_id) as nb_issues, 
b.rental_price * count(st.issued_id) as total_rev
from books as b 
join issued_status as st 
on st.issued_book_isbn = b.isbn
group by b.category, b.rental_price; 

--Task 9: List Members Who Registered in the Last 180 Days
select * 
from issued_status as st
where st.issued_date > CURRENT_DATE - INTERVAL '180 days'; 

--Task10: List Employees with Their Branch Manager's Name and their branch details
select e.emp_id, e.emp_name, t.*
from employees as e 
join (select b.branch_id, b.manager_id, e.emp_name as manager_name, b.branch_address, b.contact_no
from employees as e 
join branch as b 
on e.emp_id = b.manager_id) as t 
on e.branch_id = t.branch_id; 
--or
select e.emp_id, e.emp_name, 
b.*, m.emp_name as manager_name
from employees as e 
join branch as b 
on e.branch_id = b.branch_id 
join employees as m 
on e.emp_id = m.emp_id;

--Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:
drop table if exists expensive_books; 
Create table expensive_books
as 
(select b.* 
from books as b
where rental_price>8.00);

select * from expensive_books;

--Task 12: Retrieve the List of Books Not Yet Returned
select i.issued_id, i.issued_book_name, i.issued_date
from issued_status as i 
left join return_status as r
on i.issued_id= r.issued_id
where r.return_id is null; 


--Task 13: Identify Members with Overdue Books
select i.issued_member_id as member_id,
m.member_name as member_name, 
i.issued_book_name as book_title, 
i.issued_date as issued_date, 
i.issued_date+ INTERVAL '30 days' as overdue_date
from issued_status as i 
left join 
return_status as r
on i.issued_id= r.issued_id
join members as m 
on m.member_id = i.issued_member_id
where r.return_id is null
and CURRENT_DATE > i.issued_date+ INTERVAL '30 days'; 

--Task 14: Update Book Status on Return
CREATE OR REPLACE PROCEDURE return_book ( p_r_id varchar(10), p_i_id varchar(10))
language plpgsql
as $$ 
	DECLARE 
	bk_id varchar(50);
	bk_name varchar(50);
	begin 
		select issued_book_name,
		issued_book_isbn 
		INTO bk_name, 
		bk_id
		from issued_status 
		where issued_id=p_i_id; 

		INSERT INTO return_status(return_id, issued_id, return_book_name, return_date, return_book_isbn)
		values (p_r_id, p_i_id, bk_name, current_date, bk_id);

		UPDATE books 
		set status='yes'
		where isbn=bk_id; 
		
		RAISE NOTICE 'Thank you for returning the book: %', bk_name; 
	end;
$$; 

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

CALL return_book('RS138', 'IS135');


SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

--Task 15: Branch Performance Report
select e.branch_id, count(i.issued_id) as nb_issued_books, 
count(r.return_id) as nb_returned_books, 
sum(b.rental_price) as total_revenue
from issued_status as i
join employees as e 
on i.issued_emp_id=e.emp_id
left join return_status as r
on i.issued_id = r.issued_id
join books as b 
on b.isbn = i.issued_book_isbn
group by e.branch_id; 


--Task 16: CTAS: Create a Table of Active Members

CREATE TABLE active_members 
as 
(select distinct(m.member_name)
 from members as m 
 join issued_status as i
 on i.issued_member_name = m.member_name
 where i.issued_date >= current_date - interval '2 months'
); 

--Task 17: Find Employees with the Most Book Issues Processed
select i.issued_emp_id as emp_id, 
		e.emp_name, 
		count(i.issued_id) as nb_book_processed, 
		e.branch_id
from issued_status as i 
join employees as e 
on i.issued_emp_id = e.emp_id
group by i.issued_emp_id, e.emp_name, e.branch_id
order by nb_book_processed desc
limit 3; 


--Task 19: Stored Procedure Objective: 
CREATE OR REPLACE PROCEDURE issue_books (p_bk_id char(15), p_issue_id char(15), p_member_id char(15), p_emp_id char(15)) 
language plpgsql
as $$
declare 
bk_status char(10);
bk_name char(50);
	begin
	select status, book_title
	into bk_status, bk_name
	from books 
	where isbn=p_bk_id; 
	
	if bk_status='yes' then
		insert into issued_status(issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
		VALUES (p_issue_id, p_member_id, bk_name, current_date, p_bk_id, p_emp_id); 
		UPDATE books 
		set status='no'
		where isbn=p_bk_id; 
	ELSE 
		RAISE NOTICE 'BOOK WITH ID % IS NOT AVAILABLE!', p_bk_id;
	END IF; 
	end; 
$$; 

SELECT * FROM books
WHERE isbn='978-0-375-41398-8';
CALL issue_books('978-0-375-41398-8','IS156', 'C108', 'E104');

SELECT * FROM books
WHERE isbn='978-0-553-29698-2';

CALL issue_books('978-0-553-29698-2','IS155', 'C108', 'E104');

SELECT * FROM issued_status
WHERE issued_book_isbn='978-0-553-29698-2';

--Task 20: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
select distinct(member_id) as member_id, 
		sum(late_days) as total_late_days, 
		sum(late_days)*0.5 as total_fine
from
(select i.issued_member_id as member_id, 
		i.issued_date, 
		current_date - (i.issued_date::date + 30) as late_days
from issued_status as i 
left join return_status as r
on i.issued_id = r.issued_id
where r.return_id IS NULL
 ) as t 
group by 1; 
		
		



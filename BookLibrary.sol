// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";

contract BookLibrary is Ownable {
    event BookAdded(uint bookId, string title, uint count);
    event BookBorrowed(address borrower, uint _bookId, uint remaining);
    event BookReturned(address brorrower, uint _bookId, uint remaining);

    Book[] public books;

    struct Book {
        uint id;
        string title;
    }
    struct Borrow {
        uint bookId;
        address borrower;
    }

    mapping(uint => Book) booksMap;
    mapping(uint => uint) bookCount;
    mapping(uint => address[]) bookBorrowers;
    mapping(address => Book[]) borrowsPerUser;


    function addBook(string memory _title, uint _count) public onlyOwner {
        Book memory book = _createBook(_title);
        books.push(book);
        booksMap[book.id] = book;
        bookCount[book.id] += _count;

        emit BookAdded(book.id, _title, bookCount[book.id]);
    }

    // Users should be able to see the available books and borrow them by their id.
    function availableBooks() public view returns (Book[] memory) {
        uint size;
        for (uint i = 0; i < books.length; i++) {
            if (bookCount[books[i].id] > 0) {
                size++;
            }
        }
        Book[] memory available = new Book[](size);
        size = 0;
        for (uint i = 0; i < books.length; i++) {
            if (bookCount[books[i].id] > 0) {
                available[size] = books[i];
                size++;
            }
        }
        return available;
    }

    // Everyone should be able to see the addresses of all people that have ever borrowed a given book.
    function borrowers(uint _bookId) public view returns(address[] memory) {
        return bookBorrowers[_bookId];
    }

    //
    function borrowBook(uint _bookId) public {
        // The users should not be able to borrow a book more times than the copies in the libraries unless copy is returned.
        require(bookCount[_bookId] >= 1, "There are no available books at this moment.");
        bool alreadyBorrowed = false;
        Book[] memory borrowedByUser = borrowsPerUser[msg.sender];
        for (uint i = 0; i < borrowedByUser.length; i++) {
            if (borrowedByUser[i].id == _bookId) {
                alreadyBorrowed = true;
                break;
            }
        }
        require(!alreadyBorrowed, "A user should not borrow more than one copy of a book at a time.");

        bookBorrowers[_bookId].push(msg.sender);
        borrowsPerUser[msg.sender].push(books[_bookId]);
        bookCount[_bookId]--;


        emit BookBorrowed(msg.sender, _bookId, bookCount[_bookId]);
    }

    // Users should be able to return books.
    function returnBook(uint _bookId) public {
        // require(msg.sender == bookBorrowers[_bookId]);

        emit BookReturned(msg.sender, _bookId, bookCount[_bookId]);
    }

    function _createBook(string memory _title) internal pure returns (Book memory) {
        uint bookId = _generateId(_title);
        return Book(bookId, _title);
    }

    // function to generate a unique id from the name of the book
    function _generateId(string memory _title) internal pure returns (uint) {
        uint id = uint(keccak256(abi.encodePacked(_title)));
        return id;
    }
}

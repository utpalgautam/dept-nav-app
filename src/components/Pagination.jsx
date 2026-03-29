import React from 'react';

const Pagination = ({ currentPage, totalItems, itemsPerPage, onPageChange }) => {
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  
  if (totalPages <= 1 && totalItems <= itemsPerPage) {
    if (totalItems === 0) return null;
    return (
      <div className="user-pagination">
        <span className="pagination-info">Showing 1 to {totalItems} of {totalItems}</span>
      </div>
    );
  }

  const startIdx = (currentPage - 1) * itemsPerPage + 1;
  const endIdx = Math.min(currentPage * itemsPerPage, totalItems);

  const renderPageNumbers = () => {
    const pages = [];
    let startPage, endPage;

    if (totalPages <= 3) {
      startPage = 1;
      endPage = totalPages;
    } else {
      if (currentPage === 1) {
        startPage = 1;
        endPage = 3;
      } else if (currentPage === totalPages) {
        startPage = totalPages - 2;
        endPage = totalPages;
      } else {
        startPage = currentPage - 1;
        endPage = currentPage + 1;
      }
    }

    for (let i = startPage; i <= endPage; i++) {
      pages.push(
        <div
          key={i}
          className={`page-num ${currentPage === i ? 'active' : ''}`}
          onClick={() => onPageChange(i)}
        >
          {i}
        </div>
      );
    }
    return pages;
  };

  return (
    <div className="user-pagination">
      <span className="pagination-info">
        Showing {startIdx} to {endIdx} of {totalItems}
      </span>
      <div className="user-pages">
        <div 
          className={`page-nav ${currentPage === 1 ? 'disabled' : ''}`}
          onClick={() => currentPage > 1 && onPageChange(currentPage - 1)}
        >
          &lt;
        </div>
        
        {renderPageNumbers()}

        <div 
          className={`page-nav ${currentPage === totalPages ? 'disabled' : ''}`}
          onClick={() => currentPage < totalPages && onPageChange(currentPage + 1)}
        >
          &gt;
        </div>
      </div>
    </div>
  );
};

export default Pagination;

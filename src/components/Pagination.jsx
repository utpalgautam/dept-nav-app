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
    for (let i = 1; i <= totalPages; i++) {
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
      <span className="pagination-info">Showing {startIdx} to {endIdx} of {totalItems}</span>
      <div className="user-pages">
        <span 
          className="page-nav"
          style={{ cursor: currentPage > 1 ? 'pointer' : 'default', opacity: currentPage > 1 ? 1 : 0.4 }}
          onClick={() => currentPage > 1 && onPageChange(currentPage - 1)}
        >
          &lt;
        </span>
        
        {renderPageNumbers()}

        <span 
          className="page-nav"
          style={{ cursor: currentPage < totalPages ? 'pointer' : 'default', opacity: currentPage < totalPages ? 1 : 0.4 }}
          onClick={() => currentPage < totalPages && onPageChange(currentPage + 1)}
        >
          &gt;
        </span>
      </div>
    </div>
  );
};

export default Pagination;

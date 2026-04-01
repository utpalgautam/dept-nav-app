/**
 * Returns true if every character in `query` appears in `text`
 * in order (but not necessarily consecutively) — subsequence matching.
 * Both arguments are compared case-insensitively.
 *
 * Examples:
 *   matchesSubsequence('fmy', 'Faculty Management') → true  ("F..M..y")
 *   matchesSubsequence('cse', 'Computer Science')   → true
 *   matchesSubsequence('xyz', 'Computer Science')   → false
 */
export const matchesSubsequence = (query, text) => {
  if (!query) return true;
  const q = query.toLowerCase();
  const t = (text || '').toLowerCase();
  let qi = 0;
  for (let ti = 0; ti < t.length && qi < q.length; ti++) {
    if (t[ti] === q[qi]) qi++;
  }
  return qi === q.length;
};

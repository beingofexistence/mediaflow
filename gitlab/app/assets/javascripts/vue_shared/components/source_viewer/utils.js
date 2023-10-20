const BLAME_INFO_CLASSLIST = ['gl-border-t', 'gl-border-gray-500', 'gl-pt-3!'];
const PADDING_BOTTOM_LARGE = 'gl-pb-6!';
const PADDING_BOTTOM_SMALL = 'gl-pb-3!';

const findLineNumberElement = (lineNumber) => document.getElementById(`L${lineNumber}`);

const findLineContentElement = (lineNumber) => document.getElementById(`LC${lineNumber}`);

export const calculateBlameOffset = (lineNumber) => {
  if (lineNumber === 1) return '0px';
  const lineContentOffset = findLineContentElement(lineNumber)?.offsetTop;
  return `${lineContentOffset}px`;
};

export const toggleBlameClasses = (blameData, isVisible) => {
  /**
   * Adds/removes classes to line number/content elements to match the line with the blame info
   * */
  const method = isVisible ? 'add' : 'remove';
  blameData.forEach(({ lineno, span }) => {
    const lineNumberEl = findLineNumberElement(lineno)?.parentElement;
    const lineContentEl = findLineContentElement(lineno);
    const lineNumberSpanEl = findLineNumberElement(lineno + span - 1)?.parentElement;
    const lineContentSpanEl = findLineContentElement(lineno + span - 1);

    lineNumberEl?.classList[method](...BLAME_INFO_CLASSLIST);
    lineContentEl?.classList[method](...BLAME_INFO_CLASSLIST);

    if (span === 1) {
      lineNumberSpanEl?.classList[method](PADDING_BOTTOM_LARGE);
      lineContentSpanEl?.classList[method](PADDING_BOTTOM_LARGE);
    } else {
      lineNumberSpanEl?.classList[method](PADDING_BOTTOM_SMALL);
      lineContentSpanEl?.classList[method](PADDING_BOTTOM_SMALL);
    }
  });
};

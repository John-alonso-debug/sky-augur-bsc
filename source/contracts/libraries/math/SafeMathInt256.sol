pragma solidity 0.5.16;


/**
 * @title SafeMathInt256
 * @dev Int256 math operations with safety checks that throw on error
 */
library SafeMathInt256 {
  // Signed ints with n bits can range from -2**(n-1) to (2**(n-1) - 1)
  int256 private constant INT256_MIN = -2**(255);
  int256 private constant INT256_MAX = (2**(255) - 1);

  function mul(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a * b;
    require(a == 0 || c / a == b, "Multiplication failed");
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    // Solidity only automatically asserts when dividing by 0
    require(b != 0, "Divisor cannot be 0");
    int256 c = a / b;
    return c;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require(((a >= 0) && (b >= a - INT256_MAX)) || ((a < 0) && (b <= a - INT256_MIN)), "Subtraction failed");
    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    require(((a >= 0) && (b <= INT256_MAX - a)) || ((a < 0) && (b >= INT256_MIN - a)), "Addition failed");
    return a + b;
  }

  function min(int256 a, int256 b) internal pure returns (int256) {
    if (a <= b) {
      return a;
    } else {
      return b;
    }
  }

  function max(int256 a, int256 b) internal pure returns (int256) {
    if (a >= b) {
      return a;
    } else {
      return b;
    }
  }

  function getInt256Min() internal pure returns (int256) {
    return INT256_MIN;
  }

  function getInt256Max() internal pure returns (int256) {
    return INT256_MAX;
  }
}

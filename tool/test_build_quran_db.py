import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from build_quran_db import normalize_arabic


class BuildQuranDbTest(unittest.TestCase):
    def test_normalize_arabic_removes_diacritics(self) -> None:
        self.assertEqual(
            normalize_arabic("إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ"),
            "انا اعطيناك الكوثر",
        )


if __name__ == "__main__":
    unittest.main()

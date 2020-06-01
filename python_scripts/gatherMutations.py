import os
import glob
import csv
from python_scripts.pitest_html_parser import *

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MUTATION_RESULTS = os.path.abspath(os.path.join(BASE_DIR, 'mutation_results'))

file = open('mutationScoresGathered.csv', 'w', newline='')
writer = csv.writer(file)


writer.writerow(['Project', 'Class', 'MutationScore'])
for project in os.listdir(MUTATION_RESULTS):
    for test in os.listdir(os.path.join(MUTATION_RESULTS, project)):
        path = '{}/'.format(MUTATION_RESULTS) + project + '/' + test + '/**/index.html'
        mutation_files = glob.glob(path, recursive=False)
        for mutation_file in mutation_files:
            writer.writerow([project, test.split(".")[-1], PitestHTMLParser(mutation_file).get_mutation_coverage()])

file.close()

import sys
import os
linkfile = sys.argv[1]
print(linkfile+'.txt')
from fpdf import FPDF  
class PDF(FPDF):
    def header(self):
        # Logo
        self.image('/home/pi/scan/logosh.jpg', 10, 8, 33)
        # Arial bold 15
        self.set_font('Arial', 'B', 15)
        # Move to the right
        self.cell(80)
        # Title
        self.cell(30, 10, 'Analisi Sonda - Serpeddì', 0, 0, 'C')
        # Line break
        self.ln(20)

    # Page footer
    def footer(self):
        # Position at 1.5 cm from bottom
        self.set_y(-15)
        # Arial italic 8
        self.set_font('Arial', 'I', 8)
        # Page number
        self.cell(0, 10, 'Pagina ' + str(self.page_no()) + '/{nb}', 0, 0, 'C')




pdf = PDF() 
pdf.add_page() 
pdf.alias_nb_pages()
pdf.set_font("Arial", size = 10) 
f = open(linkfile+'.txt', "r") 
for raw in f:
	x= raw.replace("|"," ") 
	pdf.cell(0, 8, txt = x, ln = 1, align = 'L') 
pdf.output(linkfile+'.pdf')
os.remove(linkfile+'.txt')

try:
    import reportlab
    print("reportlab", reportlab.Version)
except Exception as e:
    print("reportlab MISSING", e)
try:
    import fpdf
    print("fpdf ok")
except Exception as e:
    print("fpdf MISSING", e)
try:
    import weasyprint
    print("weasyprint ok")
except Exception as e:
    print("weasyprint MISSING", e)
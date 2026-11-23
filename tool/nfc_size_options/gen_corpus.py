"""Synthetic corpus for the NFC size measurements (tool/nfc_size_options).

The NFC capacity analysis of 21 Oct 2026 measured 100 synthetic patients
(49 with two guardians; 0, 1, 2 and 3 allergies in 34, 23, 31 and 12 of them;
one consultation each, with no diagnosis), plus histories assembled from other
patients' consultations, each with 1 or 2 diagnoses (ICD-10, ICD-11,
description and `source`), and a "long text" variant that joins each clinical
field with the same field of two other consultations. That corpus is not
versioned anywhere, so this script rebuilds one from the same description, with
every field of the app's model filled in.

The vocabulary is Spanish, as the app's users write, and it is new: none of it
comes from the generator of the compression audit, which is what format 2's
dictionary 1 was built from, so the dictionary is never measured against its
own training text. What the app takes from a catalog (vaccines, relationships,
document types, allergy categories) comes from the app's catalog.

Dates have the shape the app writes (`toIso8601WithOffset`: seconds and
offset). Phones are stored as typed (the field's hint is `+57 310 482 9914`).
Invented data only: no real record.

Usage: python3 -I gen_corpus.py OUT.json [--escala-texto F] [--seed N] [--backend CLONE]
--escala-texto 0.3 (the default) is the scale calibrated against the 21 Oct
figures; --backend names a clone of guane-hwb/health-without-borders to add its
contract fixtures (optional). The same arguments give the same file.
"""

import argparse
import json
import random
import subprocess
import sys
from datetime import date, datetime, timedelta

# ── Vocabulary (new; Spanish data) ──────────────────────────────────────────

NOMBRES_F = ["Ariadna", "Bianca", "Celeste", "Doris", "Elena", "Fabiola", "Greisy",
             "Heidy", "Ingrid", "Johana", "Karelys", "Lorena", "Marbelis", "Nairobis",
             "Omaira", "Paola", "Rosmery", "Soraya", "Tibisay", "Wendy", "Yamileth",
             "Zuleima", "Andreína", "Belkis", "Carolay", "Dulce", "Esther", "Francis",
             "Glendys", "Hilda"]
NOMBRES_M = ["Adrián", "Benjamín", "César", "Darwin", "Eduardo", "Franklin", "Gustavo",
             "Héctor", "Isaac", "Jairo", "Kevin", "Leonel", "Manuel", "Néstor", "Óscar",
             "Pablo", "Rafael", "Simón", "Tomás", "Víctor", "Wilfredo", "Yeison",
             "Abraham", "Bernardo", "Cristian", "Elías", "Fernando", "Hugo", "Iván", "Joel"]
APELLIDOS = ["Acosta", "Barrios", "Castillo", "Delgado", "Escobar", "Figueroa", "Gil",
             "Herrera", "Ibarra", "Jiménez", "Lozada", "Márquez", "Navarro", "Ochoa",
             "Paredes", "Quiroz", "Rangel", "Silva", "Tovar", "Urbina", "Vargas", "Zapata",
             "Aguilar", "Bermúdez", "Cárdenas", "Espinoza", "Flores", "Gutiérrez",
             "Hurtado", "Infante", "Lara", "Medina", "Núñez", "Osorio", "Pineda", "Reyes",
             "Sosa", "Toro", "Valero", "Arismendi"]

CIUDADES = [("Cúcuta", "54001", "Norte de Santander"), ("Los Patios", "54405", "Norte de Santander"),
            ("Villa del Rosario", "54874", "Norte de Santander"), ("Tibú", "54810", "Norte de Santander"),
            ("Ocaña", "54498", "Norte de Santander"), ("Maicao", "44430", "La Guajira"),
            ("Uribia", "44847", "La Guajira"), ("Riohacha", "44001", "La Guajira"),
            ("Arauca", "81001", "Arauca"), ("Saravena", "81736", "Arauca"),
            ("Bogotá D.C.", "11001", "Bogotá D.C."), ("Soacha", "25754", "Cundinamarca"),
            ("Barranquilla", "08001", "Atlántico"), ("Soledad", "08758", "Atlántico"),
            ("Cartagena", "13001", "Bolívar"), ("Bucaramanga", "68001", "Santander"),
            ("Floridablanca", "68276", "Santander"), ("Medellín", "05001", "Antioquia"),
            ("Bello", "05088", "Antioquia"), ("Cali", "76001", "Valle del Cauca"),
            ("Ipiales", "52356", "Nariño"), ("Pasto", "52001", "Nariño")]
BARRIOS = ["La Ermita", "Comuneros", "Camilo Daza", "Atalaya", "Juan Frío", "La Parada",
           "Brisas del Norte", "El Talento", "Nueva Esperanza", "San Mateo", "Los Almendros",
           "Villa Antigua", "El Porvenir", "Divino Niño", "La Fortaleza"]

# The app's catalogs (add_vaccine_screen.dart, the register steps and sheets).
VACUNAS_APP = [("BCG (Tuberculosis)", "19"), ("Hepatitis B", "08"), ("Pentavalente (DPT+HB+Hib)", "01"),
               ("Polio oral (VOP)", "02"), ("Polio inactivada (VIP)", "10"), ("Triple Viral (SRP)", "03"),
               ("Varicela", "21"), ("Influenza pediátrica", "141"), ("Neumococo (PCV13)", "133"),
               ("Rotavirus", "116"), ("Meningococo", "108"), ("Fiebre amarilla", "37"), ("COVID-19", "213")]
DOC_PACIENTE = ["RC", "RC", "RC", "TI", "TI", "PT", "PT", "PE", "MS", "SC", "CN", "PA"]
DOC_ADULTO = ["CC", "CE", "PT", "PT", "PE", "PA", "SC"]
PARENTESCO = ["01", "01", "01", "02", "02", "03", "04", "05"]
CATEGORIA_ALERGIA = ["01", "02", "03", "04", "05", "06"]

ALERGIAS = [  # (category, allergen, possible reactions)
    ("01", "Trimetoprim-sulfa", ["Exantema en tronco", "Ronchas en brazos"]),
    ("01", "Dipirona", ["Angioedema de labios", "Ronchas generalizadas"]),
    ("01", "Ceftriaxona", ["Exantema en la infusión", "Prurito y rubor facial"]),
    ("01", "Aspirina", ["Broncoespasmo", "Sibilancias y tos"]),
    ("01", "Carbamazepina", ["Ampollas en la boca", "Fiebre y exantema"]),
    ("02", "Mariscos", ["Anafilaxia, requirió adrenalina", "Edema facial y vómito"]),
    ("02", "Fresa", ["Ronchas peribucales", "Prurito oral inmediato"]),
    ("02", "Soya", ["Diarrea y cólico", "Distensión abdominal"]),
    ("02", "Pescado", ["Edema de lengua", "Vómito profuso"]),
    ("02", "Leche de vaca", ["Sangre en heces", "Reflujo y rechazo"]),
    ("03", "Ácaros", ["Rinorrea y estornudos", "Tos nocturna"]),
    ("03", "Pelo de gato", ["Conjuntivitis y estornudos", "Sibilancias al contacto"]),
    ("04", "Hormiga", ["Inflamación local extensa", "Ronchas a distancia"]),
    ("05", "Contraste yodado", ["Náuseas y ronchas", "Hipotensión transitoria"]),
    ("06", "Níquel", ["Dermatitis de contacto", "Eccema en las orejas"]),
]

CRONICAS = [  # (description, ICD-10, ICD-11, coded display)
    ("Rinitis alérgica perenne", "J30.3", "CA08.01", "Otras rinitis alérgicas"),
    ("Asma intermitente", "J45.0", "CA23.0", "Asma predominantemente alérgica"),
    ("Hipotiroidismo congénito en tratamiento", "E03.1", "5A00.1", "Hipotiroidismo congénito sin bocio"),
    ("Síndrome de Down", "Q90.9", "LD40.0", "Síndrome de Down, no especificado"),
    ("Parálisis cerebral espástica", "G80.0", "8D20.0", "Parálisis cerebral espástica cuadripléjica"),
    ("Talasemia menor", "D56.3", "3A50.2", "Rasgo talasémico"),
    ("Bajo peso para la talla", "R62.8", "MG44.1", "Otras faltas del desarrollo fisiológico normal esperado"),
    ("Dermatitis seborreica", "L21.9", "EA81.Z", "Dermatitis seborreica, no especificada"),
    ("Epilepsia focal controlada", "G40.1", "8A60.0", "Epilepsia sintomática relacionada con localizaciones"),
    ("Comunicación interventricular", "Q21.0", "LA88.0", "Defecto del tabique ventricular"),
    ("Retraso global del desarrollo", "F88", "6A0Z", "Otros trastornos del desarrollo psicológico"),
    ("Enfermedad por reflujo gastroesofágico", "K21.9", "DA22.Z", "Enfermedad del reflujo gastroesofágico sin esofagitis"),
]
ANTECEDENTE_FAMILIAR = [
    ("Hipertensión arterial", "I10", "BA00", "Hipertensión esencial (primaria)"),
    ("Diabetes mellitus tipo 2", "E11.9", "5A11", "Diabetes mellitus tipo 2 sin complicaciones"),
    ("Tuberculosis pulmonar", "A15.0", "1B10.0", "Tuberculosis del pulmón"),
    ("Epilepsia", "G40.9", "8A6Z", "Epilepsia, tipo no especificado"),
    ("Cáncer de mama", "C50.9", "2C6Z", "Tumor maligno de la mama, parte no especificada"),
    ("Enfermedad renal crónica", "N18.9", "GB61.Z", "Enfermedad renal crónica, no especificada"),
    ("Anemia de células falciformes", "D57.1", "3A51.1", "Anemia falciforme sin crisis"),
    ("Asma", "J45.9", "CA23.Z", "Asma, no especificada"),
]
MEDICAMENTOS_FONDO = [  # (name, DCI code, dosage)
    ("Fumarato ferroso 200 mg tableta", "19.10.1.4", "1 tableta cada 24 horas con jugo de naranja"),
    ("Montelukast 4 mg sobre granulado", "19.13.2.1", "1 sobre en la noche"),
    ("Levotiroxina 25 mcg tableta", "19.6.2.1", "1 tableta en ayunas"),
    ("Ácido valproico 250 mg/5 mL jarabe", "19.4.1.2", "4 mL cada 12 horas"),
    ("Budesonida inhalada 200 mcg", "19.13.1.3", "1 inhalación cada 12 horas con inhalocámara"),
    ("Omeprazol 20 mg cápsula", "19.11.2.1", "1 cápsula antes del desayuno"),
]

PRESTADORES = [  # (REPS code, name, NIT, site)
    ("540010214501", "IPS Salud Integral Frontera", "900456123", "01"),
    ("544050087201", "Hospital Local de Los Patios", "807008824", "02"),
    ("540010341801", "Unidad Básica de Atención Comuneros", "890501019", "03"),
    ("444300112901", "Centro de Atención Primaria Paraguachón", "901234876", "01"),
    ("818360045601", "Equipo Extramural Saravena", "834001482", "05"),
    ("110010555501", "Clínica Santa Ana", "860015536", "01"),
]
PROFESIONALES = [  # (first name, last name, second name, second last name)
    ("Natalia", "Romero", "", "Vega"), ("Julián", "Pardo", "Andrés", ""), ("Claudia", "Ríos", "Patricia", "Mesa"),
    ("Mauricio", "Lemus", "", ""), ("Verónica", "Sandoval", "", "Lugo"), ("Fredy", "Niño", "Alonso", "Ardila"),
    ("Liliana", "Zuluaga", "", "Toro"), ("Ramiro", "Cuéllar", "José", ""),
]
PAGADORES = [("EPSS41", "Nueva EPS régimen subsidiado"), ("ESSC62", "Asmet Salud"),
             ("ESS118", "Emssanar"), ("CCFC33", "Comfaoriente"), ("PPNA", "Población pobre no asegurada"),
             ("MIGR", "Migrante sin afiliación")]
VACUNADORES = ["Rocío Pabón", "Wilson Ardila", "Mileidy Quintana", "Esteban Rozo", "Sandra Liliana Mora",
               "Yesica Camargo"]
SITIOS_VACUNA = ["Punto de vacunación Terminal de Transportes", "Centro de salud Puente Barco",
                 "Vacunatorio Hospital Local Los Patios", "Jornada casa a casa barrio Camilo Daza",
                 "Puesto fijo Atalaya", "Brigada en asentamiento Brisas del Norte"]

SINTOMAS = ["alza térmica no medida", "picos febriles de hasta 39 °C", "tos productiva de predominio nocturno",
            "secreción nasal amarillenta", "estornudos frecuentes", "evacuaciones blandas cinco veces al día",
            "emesis en tres ocasiones", "rechazo parcial a la vía oral", "irritabilidad", "llanto inconsolable",
            "dolor de oído izquierdo", "brote papular en extremidades", "picazón en cuero cabelludo",
            "ardor al orinar", "dolor tipo cólico periumbilical", "astenia y adinamia", "respiración ruidosa",
            "disminución del apetito", "lesiones con costra melicérica", "ojo rojo con secreción",
            "dolor de garganta al tragar", "deposiciones con moco", "fatiga al jugar"]
COMPLEMENTOS = ["Sin antecedente de viaje reciente.", "Convive con hermano con síntomas similares.",
                "Recibió acetaminofén en casa con mejoría parcial.", "Esquema de vacunación incompleto según carné.",
                "Llegaron al país hace {w} semanas por el corredor de Paraguachón.",
                "Vive en asentamiento sin acceso continuo a agua potable.",
                "Duerme en habitación compartida con cinco personas.",
                "Asiste a hogar comunitario del ICBF.", "Consultó hace una semana en otra institución sin mejoría.",
                "La madre suspendió la lactancia hace {w} semanas."]
ESTADO_GENERAL = ["Alerta, hidratado, sin dificultad respiratoria.", "Somnoliento pero reactivo, mucosas secas.",
                  "Activo y reactivo, afebril al examen.", "Irritable al examen, consolable en brazos de la madre.",
                  "Pálido, con ojeras, sin signos de deshidratación."]
HALLAZGOS = ["Otoscopia izquierda con tímpano opaco y abombado.", "Orofaringe hiperémica con amígdalas grado II.",
             "Murmullo vesicular conservado, roncus aislados.",
             "Abdomen con ruidos aumentados, sin signos de irritación peritoneal.",
             "Lesiones papulovesiculares en pliegues interdigitales.", "Costras amarillentas perinasales.",
             "Conjuntiva bulbar hiperémica con secreción purulenta.", "Liendres adheridas al tallo piloso.",
             "Placas blanquecinas en mucosa yugal que no se desprenden.", "Eritema en área del pañal con lesiones satélite.",
             "Tiraje subcostal leve, sin aleteo nasal.", "Hígado a 2 cm del reborde costal."]
SISTEMAS = ["Respiratorio", "Digestivo", "Piel y faneras", "Otorrinolaringológico", "Neurológico", "Urinario",
            "Ojos"]
RECOMENDACIONES = ["Ofrecer líquidos en pequeñas cantidades y con frecuencia.", "Mantener la lactancia a libre demanda.",
                   "Lavar la ropa de cama con agua caliente.", "Aplicar compresas tibias en el ojo afectado.",
                   "Evitar el humo de leña dentro de la vivienda.", "Se entrega folleto de signos de alarma.",
                   "Se educa a la madre en técnica de lavado nasal.", "Se refuerza higiene de manos y de alimentos.",
                   "Se remite a vacunación para completar esquema.", "Se canaliza a programa de crecimiento y desarrollo."]
ALARMAS = ["presenta respiración rápida", "no recibe líquidos", "persiste la fiebre más de 48 horas",
           "aparece sangre en las heces", "convulsiona", "está muy somnoliento"]
FORMULAS = [  # (name, ATC code, dose, quantity, frequency, duration, route)
    ("Cefalexina suspensión 250 mg/5 mL", "J01DB01", "6 mL", "2 frascos", "cada 8 horas", "7 días", "oral"),
    ("Azitromicina suspensión 200 mg/5 mL", "J01FA10", "4 mL", "1 frasco", "cada 24 horas", "3 días", "oral"),
    ("Prednisolona solución oral 15 mg/5 mL", "H02AB06", "5 mL", "1 frasco", "cada 24 horas", "5 días", "oral"),
    ("Hidroxicina jarabe 10 mg/5 mL", "N05BB01", "5 mL", "1 frasco", "en la noche", "5 días", "oral"),
    ("Mebendazol 100 mg tableta", "P02CA01", "1 tableta", "6 tabletas", "cada 12 horas", "3 días", "oral"),
    ("Clotrimazol crema 1 %", "D01AC01", "capa delgada", "1 tubo", "cada 12 horas", "10 días", "tópica"),
    ("Ivermectina 6 mg tableta", "P02CF01", "1 tableta", "2 tabletas", "dosis única, repetir en 7 días", "7 días", "oral"),
    ("Nitazoxanida suspensión 100 mg/5 mL", "P01AX11", "5 mL", "1 frasco", "cada 12 horas", "3 días", "oral"),
    ("Cetirizina gotas 10 mg/mL", "R06AE07", "5 gotas", "1 frasco", "cada 24 horas", "10 días", "oral"),
    ("Paracetamol gotas 100 mg/mL", "N02BE01", "15 gotas", "1 frasco", "cada 6 horas si hay fiebre", "3 días", "oral"),
    ("Mupirocina ungüento 2 %", "D06AX09", "aplicar en lesiones", "1 tubo", "cada 8 horas", "7 días", "tópica"),
    ("Sales de rehidratación oral baja osmolaridad", "A07CA", "100 mL", "6 sobres", "después de cada deposición", "4 días", "oral"),
]
DIAGNOSTICOS = [  # (ICD-10, ICD-11, description)
    ("J02.9", "CA02.Z", "Faringitis aguda, no especificada"),
    ("H10.9", "9A60.Z", "Conjuntivitis, no especificada"),
    ("A08.4", "1A2Z", "Infección intestinal viral, sin otra especificación"),
    ("B37.0", "1F23.0", "Estomatitis candidiásica"),
    ("L22", "EH40.1", "Dermatitis del pañal"),
    ("J21.9", "CA41.Z", "Bronquiolitis aguda, no especificada"),
    ("R50.9", "MG26", "Fiebre, no especificada"),
    ("B85.0", "1G00.0", "Pediculosis debida a Pediculus humanus capitis"),
    ("J30.4", "CA08.0Z", "Rinitis alérgica, no especificada"),
    ("N30.0", "GC00.0", "Cistitis aguda"),
    ("A07.1", "1A31", "Giardiasis [lambliasis]"),
    ("H65.9", "AB00.Z", "Otitis media no supurativa, sin otra especificación"),
    ("L08.0", "1B72.0", "Pioderma"),
    ("K59.0", "DD91.1", "Constipación"),
]
DISCAPACIDAD = ["01", "02", "03", "04"]
ETNIAS = [("01", "Wayuu"), ("01", "Yukpa"), ("01", "Barí"), ("05", "Comunidad afrodescendiente de Tibú"),
          ("06", "")]


class Gen:
    def __init__(self, seed, escala):
        self.r = random.Random(seed)
        self.escala = escala

    def p(self, x):
        return self.r.random() < x

    def pick(self, xs):
        return xs[self.r.randrange(len(xs))]

    def between(self, a, b):
        return self.r.randint(a, b)

    def uuid(self):
        h = "%032x" % self.r.getrandbits(128)
        h = h[:12] + "4" + h[13:16] + "89ab"[self.r.randrange(4)] + h[17:]
        return f"{h[:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:]}"

    def uid(self):
        return ":".join(["04"] + ["%02X" % self.r.randrange(256) for _ in range(6)])

    def digits(self, n):
        return str(self.between(1, 9)) + "".join(str(self.r.randrange(10)) for _ in range(n - 1))

    def phone(self):
        u = self.r.random()
        if u < 0.45:  # as the field's hint suggests
            return f"+57 3{self.between(0, 5)}{self.r.randrange(10)} {self.digits(3)} {self.digits(4)}"
        if u < 0.80:
            return "3" + "".join(str(self.r.randrange(10)) for _ in range(9))
        return f"+58 41{self.between(2, 6)} {self.digits(3)} {self.digits(4)}"

    def doc_number(self, tipo):
        if tipo == "MS":
            return "MS" + self.digits(8)
        if tipo == "PA":
            return self.pick("ABCDEFGHJK") + self.digits(8)
        if tipo == "SC":
            return "SC" + self.digits(7)
        if tipo in ("PT", "PE"):
            return self.digits(self.between(6, 8))
        return self.digits(10)

    def nombre(self, sexo=None):
        sexo = sexo or self.pick("MF")
        return self.pick(NOMBRES_F if sexo == "F" else NOMBRES_M)

    def apellido(self):
        return self.pick(APELLIDOS)

    @staticmethod
    def iso(d: datetime) -> str:
        return d.strftime("%Y-%m-%dT%H:%M:%S") + "-05:00"

    # ── Clinical text ───────────────────────────────────────────────────────
    def n_frases(self, base):
        """Number of optional sentences, scaled by the calibration factor."""
        return max(0, round(base * self.escala + self.r.uniform(-0.5, 0.5)))

    def enfermedad_actual(self, rel):
        s = self.r.sample(SINTOMAS, 3)
        n = self.between(1, 12)
        t = self.pick([
            f"Menor traído por {rel} por cuadro de {n} días consistente en {s[0]} asociado a {s[1]}.",
            f"Paciente con {s[0]} de {n} días de evolución; {rel} refiere además {s[1]}.",
            f"Inicia hace {n} días con {s[0]}; posteriormente presenta {s[1]} y {s[2]}.",
        ])
        extra = [c.replace("{w}", str(self.between(1, 30))) for c in self.r.sample(COMPLEMENTOS, 4)]
        return " ".join([t] + extra[: self.n_frases(1.6)])

    def examen(self, peso, talla):
        t = (f"Peso {peso:.1f} kg, talla {talla:.1f} cm, FC {self.between(78, 160)} lpm, "
             f"FR {self.between(16, 52)} rpm, T {self.between(359, 398) / 10:.1f} °C, "
             f"SpO2 {self.between(89, 99)} %. {self.pick(ESTADO_GENERAL)}")
        return " ".join([t] + self.r.sample(HALLAZGOS, 4)[: self.n_frases(1.4)])

    def sistemas(self):
        k = max(1, self.n_frases(1.5))
        return " ".join(f"{sis}: {h[0].lower()}{h[1:]}" for sis, h in
                        zip(self.r.sample(SISTEMAS, k), self.r.sample(HALLAZGOS, k)))

    def plan(self, formulas):
        partes = [f"{f[0]}, {f[2]} {f[4]} por {f[5]}." for f in formulas]
        partes += self.r.sample(RECOMENDACIONES, 4)[: self.n_frases(1.6)]
        partes.append(f"Control en {self.between(2, 30)} días; consultar antes si {self.pick(ALARMAS)}.")
        return " ".join(partes)

    # ── Parts of a record ───────────────────────────────────────────────────
    def cuidador(self, ciudad, desde):
        sexo = self.pick("MF")
        tipo = self.pick(DOC_ADULTO)
        g = {
            "name": " ".join([self.nombre(sexo)] + ([self.nombre(sexo)] if self.p(0.5) else [])
                             + [self.apellido(), self.apellido()]),
            "relationship": self.pick(PARENTESCO),
            "relationshipOther": "",
            "phone": self.phone(),
            "device_uid": self.uid(),
            "documentType": tipo,
            "documentNumber": self.doc_number(tipo),
            "consent": {
                "accepted": True,
                "acceptedAt": self.iso(desde),
                "policyVersion": "v1.1",
                "signatureBase64": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==",
            },
        }
        if self.p(0.35):
            g["consent"]["email"] = f"{self.apellido().lower()}.{self.between(10, 99)}@correo.com".replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u")
        return g

    def consulta(self, cuando, peso, talla, rel, con_dx):
        ini = cuando.replace(hour=self.between(7, 17), minute=self.between(0, 59), second=self.between(0, 59))
        fin = ini + timedelta(minutes=self.between(12, 45), seconds=self.between(0, 59))
        prof = self.pick(PROFESIONALES)
        prest = self.pick(PRESTADORES)
        formulas = self.r.sample(FORMULAS, self.pick([0, 1, 1, 2]))
        c = {
            "encounterIdentifier": self.uuid(),
            "type": "Consultation",
            "startDateTime": self.iso(ini),
            "endDateTime": self.iso(fin),
            "careModality": self.pick(["01", "01", "02", "03"]),
            "serviceGroup": self.pick(["01", "01", "02"]),
            "careEnvironment": self.pick(["05", "05", "01", "02"]),
            "practitioner": {
                "documentType": "CC", "documentNumber": self.digits(10),
                "name": " ".join(x for x in [prof[0], prof[1]] if x),
                "firstName": prof[0], "firstLastName": prof[1],
            },
            "physician": " ".join(x for x in [prof[0], prof[1]] if x),
            "clinicalEvaluation": {
                "historyOfCurrentIllness": self.enfermedad_actual(rel),
                "generalPhysicalExamination": self.examen(peso, talla),
                **({"systemsExamination": self.sistemas()} if self.p(0.4) else {}),
                "treatmentPlanObservations": self.plan(formulas),
            },
            "diagnosis": [],
            "diagnosisType": self.pick(["01", "02", "03"]),
            "riskFactors": [],
            "prescriptions": [
                {"medicationName": f[0], "dosage": f[2], "frequency": f[4], "duration": f[5], "route": f[6],
                 "status": "active", "intent": "order"} for f in formulas
            ],
        }
        if self.p(0.5):
            c["provider"] = {"repsCode": prest[0], "name": prest[1]}
        if self.p(0.3):
            c["payer"] = {"name": self.pick(PAGADORES)[1]}
        if self.p(0.3):
            c["dischargeDisposition"] = "01"
        if self.p(0.05):
            c["incapacity"] = {"scope": "01", "days": self.between(1, 5)}
        if con_dx:
            self.diagnosticos(c, fin)
        return c

    def diagnosticos(self, c, fin):
        c["diagnosis"] = []
        for d in self.r.sample(DIAGNOSTICOS, self.between(1, 2)):
            c["diagnosis"].append({"icd10Code": d[0], "icd11Code": d[1], "description": d[2],
                                   "source": self.pick(["ai_suggested", "ai_suggested", "clinician"])})

    def registro(self, n_alergias, con_g2, n_cronicas=None, hoy=datetime(2026, 11, 10)):
        sexo = self.pick("MF")
        edad = self.between(0, 17)
        nac = date(hoy.year - edad - 1, 1, 1) + timedelta(days=self.between(0, 364))
        peso = 3.4 + edad * 2.7 + self.r.random() * 3
        talla = 50 + edad * 6.2 + self.r.random() * 5
        ciudad = self.pick(CIUDADES)
        tipo = self.pick(DOC_PACIENTE)
        desde = hoy - timedelta(days=self.between(60, 300), hours=self.between(0, 23))
        g1 = self.cuidador(ciudad, desde)
        rel = {"01": "la madre", "02": "el padre", "03": "la abuela", "04": "la tía", "05": "el acudiente"}[g1["relationship"]]
        etnia = self.pick(ETNIAS)
        n_cron = n_cronicas if n_cronicas is not None else self.pick([0, 0, 0, 1, 1, 1, 2, 2, 3, 4])
        pi = {
            "identification": {"documentType": tipo, "documentNumber": self.doc_number(tipo)},
            "firstName": self.nombre(sexo),
            "secondName": self.nombre(sexo) if self.p(0.6) else "",
            "firstLastName": self.apellido(),
            "secondLastName": self.apellido() if self.p(0.85) else "",
            "dob": nac.isoformat(),
            "nationalityCode": self.pick(["862", "862", "862", "170", "218"]),
            "nationalityName": "",
            "biologicalSex": sexo,
            "genderIdentity": self.pick(["01", "02", "03"]),
            "ethnicity": etnia[0],
            "ethnicCommunity": etnia[1],
            "address": {
                "street": self.pick([
                    f"Calle {self.between(1, 40)} # {self.between(1, 30)}-{self.between(1, 99)}, barrio {self.pick(BARRIOS)}",
                    f"Manzana {self.pick('ABCDEFGH')} casa {self.between(1, 40)}, asentamiento {self.pick(BARRIOS)}",
                    f"Carrera {self.between(1, 30)} # {self.between(1, 60)}-{self.between(1, 99)} apto {self.between(101, 504)}",
                    f"Vereda {self.pick(BARRIOS)}, a {self.between(1, 9)} km de la vía principal",
                ]),
                "city": ciudad[0], "cityCode": ciudad[1], "state": ciudad[2], "country": "COL",
                "countryName": "Colombia", "zone": self.pick(["01", "02"]),
            },
            "bloodType": self.pick(["O+", "O+", "O+", "A+", "B+", "AB+", "O-", "A-"]),
            "isBloodTypeCertified": self.p(0.3),
            "weight": round(peso, 1),
            "height": round(talla, 1),
        }
        if pi["nationalityCode"] == "862":
            pi["nationalityName"] = "Venezuela"
        elif pi["nationalityCode"] == "218":
            pi["nationalityName"] = "Ecuador"
        else:
            pi["nationalityName"] = "Colombia"
        if self.p(0.12):
            pi["disabilityCategory"] = self.pick(DISCAPACIDAD)
        cron = self.r.sample(CRONICAS, n_cron)
        bg = {
            "chronicConditions": [{"chronicDescription": c[0], "chronicCie10Code": c[1], "chronicCie11Code": c[2],
                                   "chronicCodedDisplay": c[3],
                                   "codingSource": self.pick(["clinician", "ai_suggested"])} for c in cron],
            "personalHistory": " ".join(self.r.sample([
                f"Producto de embarazo de {self.between(34, 40)} semanas con {self.between(0, 9)} controles prenatales.",
                f"Parto {self.pick(['vaginal en casa', 'por cesárea', 'vaginal institucional'])}, peso al nacer {self.between(2100, 3900)} g.",
                f"Hospitalización a los {self.between(2, 30)} meses por {self.pick(['neumonía', 'deshidratación', 'bronquiolitis'])}.",
                "Lactancia materna exclusiva hasta los 4 meses.",
                "Desarrollo psicomotor acorde a la edad según la madre.",
                "Sin cirugías previas.",
            ], self.n_frases(2.4))),
            "familyHistory": [{"conditionDescription": f[0], "conditionCie10Code": f[1], "conditionCie11Code": f[2],
                               "conditionCodedDisplay": f[3], "relationship": self.pick(["01", "02", "03", "04"]),
                               "codingSource": "clinician"} for f in self.r.sample(ANTECEDENTE_FAMILIAR, self.pick([0, 1, 1, 2, 2, 3]))],
            "familyHistoryNotes": self.pick(["", "", "Abuela materna con diabetes en tratamiento con insulina.",
                                             "Padre fallecido por causa no aclarada."]),
            "medications": [{"medicationName": m[0], "dciCode": m[1], "status": "active", "dosage": m[2]}
                            for m in self.r.sample(MEDICAMENTOS_FONDO, self.pick([0, 0, 1, 1, 2]))],
        }
        alg = []
        for a in self.r.sample(ALERGIAS * 2, n_alergias) if n_alergias > len(ALERGIAS) else self.r.sample(ALERGIAS, n_alergias):
            alg.append({"category": a[0], "allergen": a[1], "reaction": self.pick(a[2])})
        consulta = self.consulta(hoy - timedelta(days=self.between(1, 40)), peso, talla, rel, con_dx=False)
        vacunas = []
        for i, v in enumerate(self.r.sample(VACUNAS_APP, self.between(3, 8))):
            vacunas.append({
                "vaccinationId": self.uuid(),
                "date": (nac + timedelta(days=30 * i + self.between(0, 25))).isoformat(),
                "vaccineName": v[0], "vaccineCode": v[1], "dose": self.between(1, 3),
                "administratedBy": self.pick(VACUNADORES), "administratedAt": self.pick(SITIOS_VACUNA),
                "status": "completed",
            })
        rec = {
            "patientId": self.uuid(),
            "device_uid": self.uid(),
            "patientInfo": pi,
            "guardianInfo": g1,
            "backgroundHistory": bg,
            "allergies": alg,
            "medicalHistory": [consulta],
            "vaccinationRecord": vacunas,
            "recordVersion": self.between(1, 12),
        }
        if con_g2:
            rec["guardian2Info"] = self.cuidador(ciudad, desde)
        return rec, (peso, talla, rel)


def historiales(gen, pacientes, aux, k=10):
    """For each patient, k consultations taken from other patients, each with
    1 or 2 diagnoses (as they are after a sync), and the long-text variant:
    each clinical field joined with the same field of two other
    consultations."""
    pool = [p["medicalHistory"][0] for p in pacientes]
    campos = ("historyOfCurrentIllness", "generalPhysicalExamination", "systemsExamination",
              "treatmentPlanObservations")
    normal, largo = [], []
    for i, p in enumerate(pacientes):
        otros = [j for j in range(len(pool)) if j != i]
        elegidas = gen.r.sample(otros, k)
        base = datetime(2026, 11, 8, 9, 0, 0)
        h_n, h_l = [], []
        for n, j in enumerate(elegidas):
            c = json.loads(json.dumps(pool[j]))
            cuando = base - timedelta(days=21 * n + gen.between(0, 10))
            ini = cuando.replace(hour=gen.between(7, 17), minute=gen.between(0, 59), second=gen.between(0, 59))
            fin = ini + timedelta(minutes=gen.between(12, 45))
            c["encounterIdentifier"] = gen.uuid()
            c["startDateTime"] = Gen.iso(ini)
            c["endDateTime"] = Gen.iso(fin)
            gen.diagnosticos(c, fin)
            h_n.append(c)
            cl = json.loads(json.dumps(c))
            a, b = gen.r.sample([x for x in range(len(pool)) if x not in (i, j)], 2)
            for f in campos:
                if f not in c["clinicalEvaluation"]:
                    continue
                cl["clinicalEvaluation"][f] = " ".join(
                    x["clinicalEvaluation"][f] for x in (c, pool[a], pool[b]) if f in x["clinicalEvaluation"])
            h_l.append(cl)
        normal.append(h_n)
        largo.append(h_l)
    return normal, largo


def fixtures():
    """The backend's contract fixtures, or None without --backend."""
    if not BACKEND:
        return None
    out = {}
    for n in ("register_minor", "consultation", "vaccine"):
        raw = subprocess.run(["git", "-C", BACKEND, "show",
                              f"origin/develop:tests/contract/fixtures/{n}.json"],
                             capture_output=True, text=True, check=True).stdout
        out[n] = json.loads(raw)
    return out


BACKEND = None


def main():
    global BACKEND
    ap = argparse.ArgumentParser()
    ap.add_argument("salida")
    ap.add_argument("--escala-texto", type=float, default=0.3)
    ap.add_argument("--seed", type=int, default=20261117)
    ap.add_argument("--backend", default=None, help="clone of the backend repository (contract fixtures)")
    a = ap.parse_args()
    BACKEND = a.backend
    gen = Gen(a.seed, a.escala_texto)

    alergias = [0] * 34 + [1] * 23 + [2] * 31 + [3] * 12
    gen.r.shuffle(alergias)
    dos = [True] * 49 + [False] * 51
    gen.r.shuffle(dos)
    pacientes, aux = [], []
    for i in range(100):
        rec, x = gen.registro(alergias[i], dos[i])
        pacientes.append(rec)
        aux.append(x)
    normal, largo = historiales(gen, pacientes, aux)

    extremos = []
    for n in (3, 5, 8):
        rec, _ = gen.registro(n, True, n_cronicas=4)
        extremos.append({"alergias": n, "record": rec})

    familias = []
    for f in range(10):
        hermanos = []
        base, _ = gen.registro(gen.pick([0, 1, 2]), gen.p(0.5))
        for s in range(4):
            rec, x = gen.registro(gen.pick([0, 1, 2]), False)
            rec["guardianInfo"] = base["guardianInfo"]
            if "guardian2Info" in base:
                rec["guardian2Info"] = base["guardian2Info"]
            rec["patientInfo"]["address"] = base["patientInfo"]["address"]
            rec["patientInfo"]["firstLastName"] = base["patientInfo"]["firstLastName"]
            rec["patientInfo"]["secondLastName"] = base["patientInfo"]["secondLastName"]
            rec["medicalHistory"] = []
            cuando = datetime(2026, 11, 6, 9, 0, 0)
            for n in range(3):
                rec["medicalHistory"].append(gen.consulta(cuando - timedelta(days=25 * n), x[0], x[1], x[2], con_dx=True))
            hermanos.append(rec)
        familias.append(hermanos)

    corpus = {
        "meta": {"seed": a.seed, "escala_texto": a.escala_texto, "pacientes": 100,
                 "alergias": {"0": 34, "1": 23, "2": 31, "3": 12}, "con_dos_cuidadores": 49},
        "pacientes": pacientes,
        "historiales": {"normal": normal, "largo": largo},
        "extremos": extremos,
        "familias": familias,
        "fixtures": fixtures(),
    }
    with open(a.salida, "w", encoding="utf-8") as fh:
        json.dump(corpus, fh, ensure_ascii=False)
    print(f"corpus: {a.salida} ({len(pacientes)} patients, text scale {a.escala_texto})")


if __name__ == "__main__":
    main()

# Prepare dependencies jars into a work dir
mvn dependency:copy-dependencies -DoutputDirectory=running_work_dir -Dhttps.protocols=TLSv1.2
